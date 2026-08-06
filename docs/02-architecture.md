# 02 — Architecture

**Status: specified.** Stack is decided: **Go for the service, Rust for the pure core, Flutter for the app.**

## Shape

Four processes, and each language is there for a reason.

- **The service** (`dreamjob-server`, **Go**) runs on the user's machine: HTTP API, scheduler, ingestion, SQLite, the apply pipeline, the submitter, the mailbox, the credential vault, and supervision of the other two processes.
- **The core** (`dreamjob-core`, **Rust**) is a command-line binary with no I/O of its own: normalization, dedup fingerprinting, the matcher, and resume assembly/render/verification. Go pipes it JSON on stdin and reads JSON off stdout.
- **The app** (`dreamjob-app`, **Flutter/Dart**) is a client, **phone first**. It holds no business logic — it renders the deck, records swipes, and drives the review, submit and challenge screens over HTTP.
- **The browser sidecar** (`browser-sidecar`, **Node + Playwright**), from M5b: drives employer forms. Loopback only. See [14](14-browser-agent.md).

```
   phone (Flutter)                    dev machine / home server
┌────────────────────┐            ┌──────────────────────────────────────┐
│  dreamjob-app      │            │  dreamjob-server (Go)                │
│  ┌──────────────┐  │            │                                      │
│  │ Deck         │  │   HTTPS    │  ┌──────────┐  ┌───────────┐         │
│  │ Review queue │◄─┼── LAN ────►│  │ JSON API │  │ Scheduler │         │
│  │ Submit gate  │  │  + token   │  └────┬─────┘  └─────┬─────┘         │
│  │ Challenges   │  │            │       │              │ cron          │
│  │ Tracker      │  │            │       │        ┌─────▼──────┐        │
│  │ Profile      │  │            │       │        │ Ingestor   │        │
│  └──────────────┘  │            │       │        │ (adapters) │───────────► job boards
│  local cache       │            │       │        └─────┬──────┘        │
│  (sqlite/drift)    │            │       │              │               │
└────────────────────┘            │       │        ┌─────▼──────────┐    │
                                  │       │        │ core normalize │◄──── dreamjob-core
                                  │       │        │   + fingerprint│      (Rust subprocess)
                                  │       │        └─────┬──────────┘    │
                                  │       │        ┌─────▼─────┐         │
                                  │       ├───────►│  Store    │         │
                                  │       │        │  SQLite   │         │
                                  │       │        └─────┬─────┘         │
                                  │       │        ┌─────▼──────┐        │
                                  │       │        │ core match │◄──── dreamjob-core
                                  │       │        └─────┬──────┘        │
                                  │       │   right swipe│               │
                                  │       │        ┌─────▼──────┐        │
                                  │       │        │ Apply queue│        │
                                  │       │        └─────┬──────┘        │
                                  │       │        ┌─────▼──────────┐    │
                                  │       │        │ Tailoring agent│───────► Claude API
                                  │       │        └─────┬──────────┘    │
                                  │       │        ┌─────▼──────────┐    │
                                  │       │        │ core render    │◄──── dreamjob-core
                                  │       │        │   + verify     │      │
                                  │       │        └─────┬──────────┘    │
                                  │       │        ┌─────▼──────┐        │
                                  │       └───────►│Review gate │        │
                                  │        (human) └─────┬──────┘        │
                                  │                ┌─────▼──────┐        │
                                  │                │ Submitter  │───────────► employer ATS
                                  │                └─────┬──────┘        │
                                  │                ┌─────▼──────┐        │
                                  │                │  Tracker   │        │
                                  │                └────────────┘        │
                                  └──────────────────────────────────────┘
```

### Submission side, in detail

The `Submitter` box expands into this from M5b ([14](14-browser-agent.md), [15](15-accounts-identity.md), [16](16-mailbox.md)):

```
                        ┌──────────────┐
   approved ───────────►│  Submitter   │  (Go)
                        └──┬───┬───┬───┘
              API path ────┘   │   └──── manual draft ──► user opens the URL
                               │ browser path
                               ▼
                        ┌──────────────────┐   loopback only
                        │ browser-sidecar  │◄──── plan (JSON, no secrets)
                        │ Node + Playwright│
                        └───┬────────┬─────┘
            credential ref  │        │  challenge
                            ▼        ▼
                    ┌────────────┐  ┌──────────────┐
                    │ OS keychain│  │ Mailbox      │──► Gmail API (read-only)
                    │ (secrets)  │  │ + app prompt │──► the user's phone
                    └────────────┘  └──────────────┘
                            │
                            ▼
                     employer ATS  ──► confirmation ──► Tracker
```

Three properties this shape exists to guarantee: the model never holds a secret (the sidecar resolves credential references after the model's last turn), the sidecar is never LAN-reachable (it holds live employer sessions), and no path reaches a submit click without a token minted from the phone.

## Why this split

The rule is **Go owns anything with a network or a clock in it; Rust owns anything that must be exactly right and touches nothing.**

| | Go — `dreamjob-server` | Rust — `dreamjob-core` |
| --- | --- | --- |
| Owns | HTTP API, scheduler, ingestion, rate limiting, retries, SQLite, pipeline orchestration, submitter, mailbox, vault, subprocess supervision | Normalization, dedup fingerprinting, the matcher, resume parse/assemble/render/verify |
| Shape | Long-running, concurrent, I/O-bound, failure-tolerant | Pure functions. Same input, same output, no clock, no network, no filesystem beyond the paths it is handed |
| Why here | `context`, goroutines, `errgroup`, tickers and timeouts are the whole ingestion and pipeline problem. An official `anthropic-sdk-go` exists | The specs already demand these be deterministic, reproducible and property-testable ([05](05-matching.md), [17](17-resume-artifacts.md)). Exhaustive `match` and `Option<T>` encode the data model's hardest rules in the type system |

**Rust is not a service.** It is a binary Go executes with a verb, JSON on stdin, JSON on stdout, exit code as the error channel. No cgo, no FFI, no gRPC, no port. This keeps the Go build pure (`modernc.org/sqlite` needs no cgo either), makes the core trivially testable from a shell, and mirrors the containment the browser sidecar already gets. The cost is process spawn per call, which is irrelevant for work that runs on a 6-hour ingestion tick or once per application.

### The cost, stated plainly

**There is no longer a shared package.** In the Dart design, `dreamjob_shared` made the app↔server contract compile-checked — change `JobPosting` and both sides failed to build until they agreed. That is gone, and it was the single strongest argument for a Dart backend.

What replaces it is a written contract with generated code on all three sides ([18](18-api-contract.md)): an OpenAPI document for the HTTP boundary and a JSON Schema for the Go↔Rust boundary, both checked into `contract/`, both generating types rather than being transcribed. **A hand-written struct that mirrors a contract type is a bug waiting to happen and is banned.** Drift between app and server is now caught by CI and contract tests instead of by the compiler, which is strictly weaker — accept it knowingly.

Second cost: **four languages** — Go, Rust, Dart, and Node for the sidecar. That is a lot of toolchain for one person. It is a deliberate trade of convenience for practice value, and the mitigation is that three of the four have narrow, well-fenced jobs.

Third: **Go's zero values fight this data model.** [03](03-data-model.md) requires that "the posting did not say" is never coerced to `false`, and Go's `bool` defaults to exactly that. Every tri-state field crosses into Go as a pointer or an explicit option type, and this is the most likely source of a silent correctness bug in the whole port.

## Components

### Scheduler (Go)
`robfig/cron` or a plain ticker, in-process. Triggers ingestion per source (default 6h; [04](04-aggregation.md)). A run that overlaps its predecessor is skipped, not queued — one machine, one user, no distributed locking. Runs that can raise a human challenge are never scheduler-started ([11](11-frontend.md)).

### Ingestor (Go)
One adapter per source, all implementing the same interface:

```go
type SourceAdapter interface {
    ID() SourceID

    // Boards/companies this adapter is configured to poll.
    Targets(ctx context.Context) ([]SourceTarget, error)

    // Fetch raw postings for one target. The runner enforces RateLimit.
    Fetch(ctx context.Context, t SourceTarget, since *time.Time) (<-chan RawPosting, error)

    RateLimit() RateLimit
    CanSubmit() bool
}

type RateLimit struct {
    RequestsPerMinute int
    Concurrency       int
}
```

Note what is **not** on this interface: `normalize`. In the Dart design it was a pure method beside the impure ones; here it moves to `dreamjob-core`, which is the honest home for it — it was always the one method with no I/O in it. Adapters fetch and hand back raw payloads; nothing else.

Rate limits are enforced by the runner (`golang.org/x/time/rate` plus a bounded worker pool), never by the adapter — see [09](09-compliance.md).

### Normalizer + dedup (Rust)
`dreamjob-core normalize` takes a raw payload plus source metadata and returns a canonical `JobPosting`; `dreamjob-core fingerprint` computes the dedup key. Pure, versioned by `normalizer_version`, re-runnable over stored raw payloads with no network. Detail in [04](04-aggregation.md).

### Store (Go)
SQLite via `modernc.org/sqlite` (pure Go, no cgo) with `sqlc` for typed queries generated from hand-written SQL. Migrations are versioned files applied on boot, forward-only.

Raw source payloads are kept verbatim in a JSON column so normalization can be re-run without re-fetching — the single most useful debugging property of the system, and it MUST NOT be dropped for storage savings.

Artifacts (tailored resumes, cover letters, receipts, traces) live on disk under `~/.dreamjob/`, referenced by path. Blobs stay out of SQLite.

### Matcher (Rust)
`dreamjob-core match` takes postings + profile + swipe history and returns `Match` values. No I/O, no model call, no clock in the hot path. Deterministic, so a deck is reproducible and a score is explainable. This is the component whose test story most justifies Rust: a property test asserting the score is monotonic in each component, plus the precision/recall harness in [05](05-matching.md).

### JSON API (Go)
`net/http` with `chi` for routing, serving JSON only — no HTML, because the UI is a native client. **The OpenAPI document in `contract/` is the source of truth**, and the Go handler signatures are generated from it with `oapi-codegen`. Full endpoint list in [18](18-api-contract.md).

**Binding and auth.** The phone cannot reach `127.0.0.1` on another machine, so the server binds to the LAN interface and requires a bearer token on every request. Pairing: the server prints a QR code containing `host:port` plus the token; the app scans it once and stores the token in `flutter_secure_storage`. Details and the security consequences in [09](09-compliance.md).

### Flutter app (Dart)
Deck, review queue, submit gate, challenges, tracker, profile editor. Its models are **generated from the same OpenAPI document** and never hand-written. Platform targets, design system and packages in [11](11-frontend.md).

### Apply queue (Go)
Right-swipes become `Application` rows in `queued`. A single worker goroutine processes them one at a time — serial, because each run costs real money and ends in a human review.

### Tailoring agent (Go)
Runs the resume skills against the specific posting. Unlike the Dart design, **an official SDK exists** — `github.com/anthropics/anthropic-sdk-go` — so the awkward choice between shelling out and hand-rolling HTTP is gone. Two paths remain, for different reasons ([07](07-apply-pipeline.md)):

1. **`claude -p` as a subprocess** — reuses the `SKILL.md` files in [`skills/`](../skills/) verbatim, with the application workspace as the working directory. Still the default, because the skills *are* the product and re-implementing them as prompt strings throws that away.
2. **`anthropic-sdk-go`** — structured tool-use, streaming, and typed responses without Claude Code installed on the host. The right choice for stages that want a schema rather than a document, such as form-field mapping ([14](14-browser-agent.md)).

Default model: `claude-opus-5`.

### Review gate (Go + app)
Blocks every application until a human approves it. Mandatory and unskippable through M6. Approves content; the browser path has a second gate at the filled form ([14](14-browser-agent.md)).

### Submitter (Go)
Three paths, preferred in order ([07](07-apply-pipeline.md) §6): a per-source API adapter where a documented application endpoint exists; the browser agent where it doesn't and the site is allowlisted; a prefilled draft and `awaiting_manual_submit` everywhere else.

### Browser sidecar (Node + Playwright)
Started and stopped by Go as a child process, bound to `127.0.0.1`. Executes a declarative plan: navigate, fill, upload, read back, wait for a human token, submit, confirm, archive a trace. Never LAN-reachable. Full spec in [14](14-browser-agent.md).

### Credential vault (Go)
A thin wrapper over the OS keychain (`security` on macOS, `secret-tool` on Linux). Site passwords and the mailbox OAuth token. The database stores references, never secrets ([15](15-accounts-identity.md)).

### Mailbox reader (Go)
`google.golang.org/api/gmail/v1` over OAuth, read-only, or IMAP for other providers. Two consumers: verification-code extraction during registration (deterministic, regex, latency-sensitive) and outcome classification for the tracker ([16](16-mailbox.md)).

### Resume renderer (Rust)
`dreamjob-core assemble | render | verify`. Parses the skills' markdown against the fixed grammar, merges it into the structured master, renders PDF (`printpdf`) and DOCX, and runs the three verification gates ([17](17-resume-artifacts.md)). Text extraction still shells out to `pdftotext` — the round-trip check needs the same extractor an ATS would plausibly use, not a Rust reimplementation of one.

### Artifact store (Go)
Content-addressed renders under `~/.dreamjob/artifacts/`, hardlinked into application workspaces. Immutable: a re-render is a new hash, never an overwrite ([17](17-resume-artifacts.md)).

### Tracker (Go)
Application lifecycle, follow-up reminders, and the outcome data that feeds M7. Fed by the mailbox reader where connected, by manual entry always.

## Data flow invariants

1. **Raw is immutable.** A stored raw payload is never rewritten. Re-ingesting appends an observation and updates `last_seen_at`.
2. **Normalization is re-runnable.** Any normalized field MUST be derivable from raw + core version. Bumping `normalizer_version` triggers a re-normalization pass, not a re-fetch.
3. **Scores are never persisted as truth.** A `Match` records the score *and* the profile version and core version that produced it.
4. **Swipes are append-only.** Undo writes a compensating event; it does not delete.
5. **Nothing is submitted without an `approved_at`.** Enforced in the submitter, not the UI.
6. **The phone is a cache, never the source of truth.** A wiped phone loses nothing; the server holds everything.
7. **No secret crosses the model boundary.** Plans carry credential references; the sidecar resolves them. A prompt, tool result, or transcript containing a password is a bug, not a leak to be redacted later.
8. **No submit without a human token.** The sidecar rejects a submit action lacking a single-use token minted by the server against that `application_id`. There is no debug flag that bypasses it.
9. **Artifacts are immutable and content-addressed.** The bytes uploaded are recoverable by hash for any past application.
10. **The core never touches the network or the clock.** Time is an input. A `dreamjob-core` invocation that reaches for `SystemTime::now()` breaks reproducibility and fails review.
11. **Contract types are generated, never transcribed.** A hand-written mirror of an OpenAPI or JSON Schema type is a defect ([18](18-api-contract.md)).

## Stack

| Layer | Choice | Note |
| --- | --- | --- |
| Service | Go 1.23+ | API, ingestion, orchestration, I/O |
| Core | Rust (2021 edition) | Pure domain logic, invoked as a subprocess |
| App | Flutter/Dart, mobile-first | [11](11-frontend.md) |
| Router | `chi` | Small, stdlib-shaped |
| DB | SQLite via `modernc.org/sqlite` + `sqlc` | Pure Go, no cgo; typed queries from real SQL |
| Scheduler | `robfig/cron` or a ticker | In-process |
| HTTP client | stdlib `net/http` + `x/time/rate` | Ingestion and submission |
| HTML parsing | `golang.org/x/net/html` or `goquery` | Career-page scraping |
| Contract | OpenAPI 3.1 + JSON Schema in `contract/` | Source of truth for all three sides ([18](18-api-contract.md)) |
| Codegen | `oapi-codegen` (Go), `serde`/`typify` (Rust), `openapi-generator` (Dart) | Types are generated, never hand-written |
| Doc extraction | `pdftotext`, `textutil` subprocesses | Same tools the skills already use |
| PDF rendering | `printpdf` (Rust) + `pdftotext` round-trip check | [17](17-resume-artifacts.md) |
| DOCX rendering | `pandoc` if present, OOXML template substitution otherwise | Only when a form demands it |
| LLM access | `claude -p` subprocess, or `anthropic-sdk-go` | An official Go SDK exists — no hand-rolled HTTP |
| Browser automation | Node + Playwright sidecar on loopback | M5b ([14](14-browser-agent.md)) |
| Secret storage | OS keychain via `security` / `secret-tool` | Never SQLite ([15](15-accounts-identity.md)) |
| Mailbox | Gmail API over OAuth (read-only), IMAP fallback | [16](16-mailbox.md) |

## Failure handling

- **Source down or rate-limited.** Exponential backoff; keep serving the existing deck. Ingestion failure surfaces as a staleness indicator, never an empty deck.
- **Normalization error on one posting.** `dreamjob-core` returns a per-item error rather than failing the batch; Go quarantines that posting with the error and continues. One malformed payload MUST NOT abort a board.
- **Core subprocess crashes or exits non-zero.** Treated as a failed pure call: the batch is retried once, then quarantined with stdin captured. A panicking core is a reproducible bug by construction — the input that caused it is on disk.
- **Agent run fails.** Application returns to `queued` with the failure recorded and the partial workspace kept. Retries capped; then `needs_attention`.
- **Submission fails.** Never auto-retry — a duplicate application is worse than a missed one. Mark `submit_failed`, surface the apply URL, let the human decide.
- **Browser sidecar crash.** The application halts at `needs_attention` with the trace kept. No orphaned browser is left holding a half-filled form, and no submit is retried.
- **Verification challenge unresolved.** The run parks at `awaiting_verification` for 5 minutes, then halts. The browser session is kept so the user can finish by hand.
- **Keychain unavailable.** Credentials are not written anywhere else. Affected sites drop to `manual-only` and say why.
- **Phone offline.** The app serves its last cached deck read-only and queues swipes locally, replaying them on reconnect. Swipe IDs are client-generated so replay is idempotent.
- **Server unreachable.** The app says so explicitly, with the last-sync time. An unreachable server must never look like an empty deck.

## Open questions

- Where does the server actually live for a real demo — the user's laptop on the same Wi‑Fi, or a small always-on host? The `air` box in [server.md](server.md) is exactly that question, and [09](09-compliance.md) has to sign off before the answer is yes.
- Is the phone's local cache a full SQLite mirror, or just the current deck? Full mirroring buys offline browsing and costs a sync protocol.
- `claude -p` subprocess vs `anthropic-sdk-go` per stage. The subprocess reuses the skills verbatim; the SDK gives schema-validated output, which form-field mapping actually wants. Probably both, split by stage — but that is two integration paths to maintain.
- Subprocess-per-call to `dreamjob-core` is simple and costs a spawn each time. If the matcher ever needs to run over tens of thousands of postings interactively, does it become a long-lived process speaking newline-delimited JSON instead?
- Is the browser sidecar's Node runtime removable by rewriting it in Rust (`chromiumoxide`)? It would cut a language, and it would also cut Playwright's auto-waiting, selector engine and trace viewer, which are most of why [14](14-browser-agent.md) is tractable. Not before M6.
