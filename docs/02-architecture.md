# 02 — Architecture

**Status: specified.** Stack is decided: **Dart everywhere** — a Flutter mobile client talking to a Dart `shelf` backend.

## Shape

Two processes and one language, plus a third process at M5b that deliberately isn't.

- **The backend** (`dreamjob_server`) runs on the user's machine: scheduler, ingestion, SQLite, matcher, apply pipeline, JSON API.
- **The app** (`dreamjob_app`) is a Flutter client, **phone first**. It holds no business logic — it renders the deck, records swipes, and drives the review queue over HTTP.
- **A shared package** (`dreamjob_shared`) holds the models from [03](03-data-model.md), compiled into both. One definition of `JobPosting`, not two that drift.
- **A browser sidecar** (Node + Playwright), from M5b onward — the one piece that is not Dart, because browser automation is where Dart's ecosystem gap is unbridgeable. It is a child process bound to `127.0.0.1`, speaking JSON. See [14](14-browser-agent.md).

```
   phone (Flutter)                    dev machine / home server
┌────────────────────┐            ┌──────────────────────────────────────┐
│  dreamjob_app      │            │  dreamjob_server (Dart, shelf)       │
│  ┌──────────────┐  │            │                                      │
│  │ Deck         │  │   HTTPS    │  ┌──────────┐  ┌───────────┐         │
│  │ Review queue │◄─┼── LAN ────►│  │ JSON API │  │ Scheduler │         │
│  │ Tracker      │  │  + token   │  └────┬─────┘  └─────┬─────┘         │
│  │ Profile      │  │            │       │              │ cron          │
│  └──────────────┘  │            │       │        ┌─────▼──────┐        │
│  local cache       │            │       │        │ Ingestor   │        │
│  (drift)           │            │       │        │ (adapters) │───────────► job boards
└────────────────────┘            │       │        └─────┬──────┘        │
        ▲                         │       │              │               │
        │ same codebase           │       │        ┌─────▼──────┐        │
┌───────┴────────────┐            │       │        │ Normalizer │        │
│ desktop build      │            │       │        │  + dedup   │        │
│ (dev convenience)  │            │       │        └─────┬──────┘        │
└────────────────────┘            │       │              ▼               │
                                  │       │        ┌───────────┐         │
                                  │       ├───────►│  Store    │         │
                                  │       │        │  SQLite   │         │
                                  │       │        └─────┬─────┘         │
                                  │       │              ▼               │
                                  │       │        ┌───────────┐         │
                                  │       │        │  Matcher  │         │
                                  │       │        └─────┬─────┘         │
                                  │       │   right swipe│               │
                                  │       │        ┌─────▼──────┐        │
                                  │       │        │ Apply queue│        │
                                  │       │        └─────┬──────┘        │
                                  │       │        ┌─────▼──────────┐    │
                                  │       │        │ Tailoring agent│───────► Claude API
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

The `Submitter` box above expands into this from M5b ([14](14-browser-agent.md), [15](15-accounts-identity.md), [16](16-mailbox.md)):

```
                        ┌──────────────┐
   approved ───────────►│  Submitter   │
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
                    │ (secrets)  │  │ + phone push │──► the user's own phone
                    └────────────┘  └──────────────┘
                            │
                            ▼
                     employer ATS  ──► confirmation ──► Tracker
```

Three properties this shape exists to guarantee: the model never holds a secret (the sidecar resolves credential references after the model's last turn), the sidecar is never LAN-reachable (it holds live employer sessions), and no path reaches a submit click without a human-minted token.

## Why Dart on both sides

- One language, one toolchain, one test runner for the whole project.
- `dreamjob_shared` makes the API contract compile-checked: change `JobPosting` and both sides fail to build until they agree. This is the single biggest reason to pick Dart over a Node or Python backend here.
- Fewer moving parts to explain and demo.

**The cost, stated plainly.** Dart's ecosystem is thinner than Node's or Python's for three jobs this project needs: HTML scraping, PDF/DOCX text extraction, and browser automation. The first two are handled by shelling out to tools the resume skills already use (`pdftotext`, `textutil`) rather than by pure-Dart libraries — see [07](07-apply-pipeline.md). Scraping uses the `html` package, which is adequate for the selector-based approach in [04](04-aggregation.md).

The third does not have a shell-out answer. Playwright has no maintained Dart binding, and browser automation is not a thing to hand-roll against the CDP wire protocol on a schedule. So M5b introduces one non-Dart process, deliberately and behind a JSON boundary narrow enough that the Dart side learns nothing about Node beyond a port number — the same containment the LangGraph sidecar gets in [13](13-practice-tracks.md). "Dart everywhere" survives as an architecture claim; it stops being literally true at the browser.

## Components

### Scheduler
`cron` package, in-process. Triggers ingestion per source (default 6h; [04](04-aggregation.md)). A run that overlaps its predecessor is skipped, not queued. One machine, one user — no distributed locking.

### Ingestor
One adapter per source, all implementing the same Dart interface:

```dart
abstract class SourceAdapter {
  SourceId get id;

  /// Boards/companies this adapter is configured to poll.
  Future<List<SourceTarget>> targets();

  /// Fetch raw postings for one target. The runner enforces [rateLimit].
  Stream<RawPosting> fetch(SourceTarget target, {DateTime? since});

  /// Map a raw payload onto the canonical shape. Pure: no network, no clock.
  JobPosting normalize(RawPosting raw, SourceTarget target, {required DateTime now});

  RateLimit get rateLimit;
  bool get canSubmit;
}

class RateLimit {
  const RateLimit({required this.requestsPerMinute, required this.concurrency});
  final int requestsPerMinute;
  final int concurrency;
}
```

Adapters are the only code that knows a source's quirks. Everything downstream sees `JobPosting`.

### Normalizer + dedup
Canonicalizes work mode, location, seniority, comp, and stack tags; computes the fingerprint; merges cross-posted duplicates. Detail in [04](04-aggregation.md).

### Store
SQLite via `drift` (typed queries, generated code, migrations, and the same package works in the Flutter app for its local cache). Raw source payloads are kept verbatim in a JSON column so normalization can be re-run without re-fetching — the single most useful debugging property of the system, and it MUST NOT be dropped for storage savings.

Artifacts (tailored resumes, cover letters, receipts) live on disk under `applications/<id>/`, referenced by path. Blobs stay out of SQLite.

### Matcher
A pure Dart function: `(JobPosting, Profile, SwipeHistory) -> Match`. No I/O, no model call in the hot path. Deterministic, so a deck is reproducible and a score is explainable. Detail in [05](05-matching.md).

### JSON API
`shelf` + `shelf_router`, serving JSON only — no HTML, because the UI is a native client. Contract published as an OpenAPI document; request/response types come from `dreamjob_shared`.

**Binding and auth.** The phone cannot reach `127.0.0.1` on another machine, so the server binds to the LAN interface and requires a bearer token on every request. Pairing: the server prints a QR code containing `host:port` plus the token; the app scans it once and stores the token in `flutter_secure_storage`. Details and the security consequences in [09](09-compliance.md).

### Flutter app
Deck, review queue, tracker, profile editor. Platform targets, design system, and packages in [11](11-frontend.md).

### Apply queue
Right-swipes become `Application` rows in `queued`. A worker `Isolate` processes them one at a time — serial, because each run costs real money and ends in a human review.

### Tailoring agent
Runs the resume skills against the specific posting. The backend is Dart, and **there is no official Anthropic Dart SDK**, so it reaches Claude one of two ways — see [07](07-apply-pipeline.md):

1. **`claude -p` as a subprocess** (recommended): reuses the `SKILL.md` files in [`skills/`](../skills/) verbatim, with the workspace as the working directory.
2. **Raw HTTP to the Messages API** (`POST https://api.anthropic.com/v1/messages`) with the skill text inlined as the system prompt. Dart has no official SDK; `package:http` against the documented endpoint is the supported path.

Default model: `claude-opus-5`.

### Review gate
Blocks every application until a human approves it. Mandatory and unskippable through M6. Approves content; the browser path has a second gate at the filled form ([14](14-browser-agent.md)).

### Submitter
Three paths, preferred in order ([07](07-apply-pipeline.md) §6): a per-source API adapter where a documented application endpoint exists; the browser agent where it doesn't and the site is allowlisted; a prefilled draft and `awaiting_manual_submit` everywhere else.

### Browser sidecar
Node + Playwright on `127.0.0.1`, started and stopped as a child process. Executes a declarative plan built by Dart: navigate, fill, upload, read back, wait for a human token, submit, confirm, archive a trace. Holds the persistent browser profiles. Never LAN-reachable. Full spec in [14](14-browser-agent.md).

### Credential vault
A thin wrapper over the OS keychain (`security` on macOS, `secret-tool` on Linux). Site passwords and the mailbox OAuth token. The database stores references, never secrets, and no keychain means no stored credentials — sites drop to manual ([15](15-accounts-identity.md)).

### Mailbox reader
Gmail API over OAuth, read-only, or IMAP for other providers. Two consumers: verification-code extraction during registration (deterministic, regex, latency-sensitive) and outcome classification for the tracker ([16](16-mailbox.md)).

### Artifact store
Content-addressed renders under `~/.dreamjob/artifacts/`, hardlinked into application workspaces. Immutable: a re-render is a new hash, never an overwrite ([17](17-resume-artifacts.md)).

### Tracker
Application lifecycle, follow-up reminders, and the outcome data that feeds M7. Fed by the mailbox reader where connected, by manual entry always.

## Data flow invariants

1. **Raw is immutable.** A stored raw payload is never rewritten. Re-ingesting appends an observation and updates `last_seen_at`.
2. **Normalization is re-runnable.** Any normalized field MUST be derivable from raw + adapter version. Bumping `normalizerVersion` triggers a re-normalization pass, not a re-fetch.
3. **Scores are never persisted as truth.** A `Match` records the score *and* the profile version and matcher version that produced it.
4. **Swipes are append-only.** Undo writes a compensating event; it does not delete.
5. **Nothing is submitted without an `approvedAt`.** Enforced in the submitter, not the UI.
6. **The phone is a cache, never the source of truth.** A wiped phone loses nothing; the server holds everything.
7. **No secret crosses the model boundary.** Plans carry credential references; the sidecar resolves them. A prompt, tool result, or transcript containing a password is a bug, not a leak to be redacted later.
8. **No submit without a human token.** The sidecar rejects a submit action lacking a single-use token minted by the server against that `applicationId`. There is no debug flag that bypasses it.
9. **Artifacts are immutable and content-addressed.** The bytes that were uploaded are recoverable by hash for any past application.

## Stack

| Layer | Choice | Note |
| --- | --- | --- |
| Language | Dart 3 (server + app + shared) | Decided |
| Server | `shelf` + `shelf_router` | Small, no framework ceremony |
| DB | SQLite via `drift` | Typed queries, migrations, works on both sides |
| Scheduler | `cron` | In-process |
| HTTP client | `package:http` or `dio` | Ingestion and the Claude API |
| HTML parsing | `html` | Career-page scraping |
| Serialization | `freezed` + `json_serializable` | In `dreamjob_shared`, used by both |
| Doc extraction | `pdftotext`, `textutil` subprocesses | Same tools the skills already use |
| PDF rendering | `pdf` package + `pdftotext` round-trip check | [07](07-apply-pipeline.md), [17](17-resume-artifacts.md) |
| DOCX rendering | `pandoc` if present, OOXML template substitution otherwise | Only when a form demands it |
| LLM access | `claude -p` subprocess, or raw HTTP to the Messages API | No official Dart SDK exists |
| Browser automation | Node + Playwright sidecar on loopback | M5b. The one non-Dart process ([14](14-browser-agent.md)) |
| Secret storage | OS keychain via `security` / `secret-tool` | Never SQLite ([15](15-accounts-identity.md)) |
| Mailbox | Gmail API over OAuth (read-only), IMAP fallback | [16](16-mailbox.md) |
| App | Flutter, mobile-first | [11](11-frontend.md) |

## Failure handling

- **Source down or rate-limited.** Exponential backoff; keep serving the existing deck. Ingestion failure surfaces as a staleness indicator, never an empty deck.
- **Normalization error on one posting.** Quarantine it with the error and continue. One malformed payload MUST NOT abort a board.
- **Agent run fails.** Application returns to `queued` with the failure recorded and the partial workspace kept. Retries capped; then `needsAttention`.
- **Submission fails.** Never auto-retry — a duplicate application is worse than a missed one. Mark `submitFailed`, surface the apply URL, let the human decide.
- **Phone offline.** The app serves its last cached deck read-only and queues swipes locally, replaying them on reconnect. Swipe IDs are client-generated so replay is idempotent.
- **Server unreachable.** The app says so explicitly, with the last-sync time. An unreachable server must never look like an empty deck.
- **Browser sidecar crash.** The application halts at `needsAttention` with the trace kept. No orphaned browser is left holding a half-filled form, and no submit is retried.
- **Verification challenge unresolved.** The run parks at `awaitingVerification` for 5 minutes, then halts. The browser session is kept so the user can finish by hand.
- **Keychain unavailable.** Credentials are not written anywhere else. Affected sites drop to `manual-only` and say why.

## Open questions

- Where does the server actually live for a real demo — the user's laptop on the same Wi‑Fi, or a small always-on host (Raspberry Pi, cheap VPS)? A VPS means the resume leaves the machine, which [09](09-compliance.md) has to sign off on first.
- Is the phone's local cache full `drift` mirroring, or just the current deck in `shared_preferences`? Full mirroring buys offline browsing and costs a sync protocol.
- `claude -p` subprocess vs raw Messages API for the tailoring agent. Subprocess reuses the skills as-is and is far less code; raw HTTP gives structured results and works without Claude Code installed on the host.
- The browser sidecar and the LangGraph sidecar ([13](13-practice-tracks.md)) are two extra runtimes. Is Python + Playwright for both worth losing Playwright's best-supported target, to install one runtime instead of two?
- Attended browser mode needs the user at the machine running the server; the product is phone-first. Does that make a desktop presence a requirement again, or is assisted mode (screenshot to the phone, tap to submit) genuinely sufficient?
