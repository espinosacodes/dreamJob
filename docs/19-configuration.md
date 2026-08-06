# 19 — Configuration & first run

**Status: specified.** M1 for the config files, M3 for pairing, M5a for the rest.

Every other doc assumes a running system with a profile, some boards, and a resume. This one covers how that state comes to exist — and it exists because "how do I actually start it" is the question a spec set most often forgets to answer, including for the person who wrote it, six months later.

## Prerequisites

| Needed | For | If missing |
| --- | --- | --- |
| Go 1.23+ | building `dreamjob-server` | Build fails |
| Rust (stable, 2021) | building `dreamjob-core` | Build fails |
| Flutter 3.x | the app | Server still runs; no UI |
| `pdftotext` (poppler) | resume extraction and render verification | **Hard blocker.** Rendering cannot be verified, so no application can be approved ([17](17-resume-artifacts.md)) |
| An OS keychain | site credentials, mailbox token | Sites drop to `manual-only` ([15](15-accounts-identity.md)) |
| Claude Code on `PATH` | the tailoring agent, path A | Falls back to `anthropic-sdk-go` ([07](07-apply-pipeline.md)) |
| `ANTHROPIC_API_KEY` | the tailoring agent | Tailoring fails; ingestion and matching still work |
| Node 20+ | the browser sidecar | M5b only; browser submission unavailable, manual drafts still work |
| `pandoc` | DOCX rendering | Falls back to OOXML substitution, then to a PDF with `format_downgrade` recorded |

**`dreamjob doctor` checks all of them** and prints what degrades rather than what breaks. That distinction matters: only `pdftotext` and a missing binary are fatal. Everything else has a stated fallback, and the command says which one is in effect.

## Configuration files

All under `~/.dreamjob/`, all YAML, all user-owned and hand-editable. **The app edits them through the API; it is never the only way to edit them.** A config you can only change through a phone screen is a config you cannot diff, back up, or fix when the phone is the thing that is broken.

| File | Holds | Doc |
| --- | --- | --- |
| `config.yaml` | Server settings: bind address, port, poll intervals, caps, feature flags | here |
| `sources.yaml` | Which boards to poll | [04](04-aggregation.md) |
| `profile.yaml` | Matching preferences | [03](03-data-model.md) |
| `answers.yaml` | The `AnswerBook` — form answers | [14](14-browser-agent.md) |
| `sites.yaml` | Browser-agent allowlist and recipe status | [14](14-browser-agent.md) |
| `accounts.yaml` | Employer accounts (mirror of `SiteAccount`; **no secrets**) | [15](15-accounts-identity.md) |
| `metrics.md` | Numbers the user has supplied, reused across applications | [07](07-apply-pipeline.md) |

**Secrets are in none of them.** `ANTHROPIC_API_KEY` comes from the environment; site passwords and the mailbox token come from the OS keychain ([09](09-compliance.md)). A config file that would accept a secret is a config file someone will paste one into, so the loader **rejects** any key matching `(?i)(password|secret|api_?key|token)` with an error naming the right home for it.

### `config.yaml`

```yaml
server:
  bind: 192.168.1.20        # LAN interface. 0.0.0.0 requires --allow-public and warns
  port: 8443
  tls: self-signed          # self-signed | none. `none` refuses non-private-range clients (09)

ingest:
  default_interval: 6h
  quarantine_after_failures: 5

match:
  threshold: 60
  stretch_band: 45

apply:
  submissions_per_hour: 5   # hard cap; the loader refuses a higher value (09)
  serial: true

browser:
  enabled: false            # M5b. Off until sites.yaml has a green entry
  sidecar_port: 8765        # 127.0.0.1 only, never configurable to a LAN address

mailbox:
  enabled: false            # M5a
  provider: gmail
  label_messages: false     # true adds the gmail.modify scope (16)

paths:
  root: ~/.dreamjob
```

Two values are **clamped, not validated**: `submissions_per_hour` cannot exceed 5, and `sidecar_port` cannot bind anything but loopback. A config file is a user's own machine and they may edit it freely — but these two encode commitments made to third parties ([09](09-compliance.md)), not preferences, so the loader lowers them and says so rather than obeying.

### `sources.yaml`

```yaml
- source: greenhouse
  boards: [stripe, figma, linear]        # board tokens
  interval: 6h
- source: lever
  boards: [netlify]
- source: careers_page
  urls: ["https://acme.com/careers"]
  interval: 24h
  robots_checked_at: 2026-08-01
```

Adding a board is a text edit and a `POST /v1/sources/sync` away. A `careers_page` entry without `robots_checked_at` refuses to load — the check in [09](09-compliance.md) is enforced by the config loader, so it cannot be skipped by forgetting.

### Validation

Config errors report **file, line, and column**, and the server refuses to start on any of them. A system that boots with a half-valid profile silently produces a wrong deck, and a wrong deck is invisible — the user just sees fewer jobs and assumes that's the market.

## First run

Ten minutes, in this order. Each step is independently useful, so an interrupted setup leaves something that works.

```
1. dreamjob doctor              # prerequisites; fix blockers before anything else
2. dreamjob init                # writes ~/.dreamjob/ with commented defaults
3. dreamjob resume import ~/cv.pdf
                                # extracts to master-resume.md and SHOWS YOU THE TEXT
4. /resume-diagnoser            # in Claude Code, against the extraction
5. edit sources.yaml            # 3-5 boards you actually care about
6. dreamjob sync --once         # first ingest; prints counts and quarantines
7. edit profile.yaml            # preferences
8. dreamjob deck                # today's matches as CLI output — no app needed yet
9. dreamjob pair                # prints a QR; scan it in the app
10. dreamjob serve              # or install the service unit
```

**Step 3 is the one people skip and shouldn't.** The extraction is shown, not assumed: if `pdftotext` mangled the master resume, every artifact built on it inherits the damage, and the mangling is also the first honest signal about how the employer's parser will see it ([17](17-resume-artifacts.md)).

**Step 8 exists so the system is useful before the app is written.** M1 and M2 deliver a CLI that prints today's ranked matches, and that ordering is deliberate ([10](10-roadmap.md)).

### M5a additions

```
dreamjob mailbox connect        # OAuth in a browser, token to the keychain
dreamjob answers edit           # or edit answers.yaml directly
dreamjob accounts list          # what accounts exist, and where
```

`mailbox connect` prints the exact scopes it is about to request and requires a typed confirmation. A grant this broad should never be one keypress away, and the user should see `gmail.readonly` with their own eyes before approving it ([16](16-mailbox.md)).

## Running it

| Mode | Command | For |
| --- | --- | --- |
| Foreground | `dreamjob serve` | Development; logs to stderr |
| Service | `dreamjob install-service` | A `systemd` unit (Linux) or `launchd` plist (macOS), restart-on-failure |
| One-shot | `dreamjob sync --once`, `dreamjob deck` | Cron-free operation, and how M1–M2 are used before there's a UI |

The server owns its children: it starts and stops the browser sidecar and invokes the core as a subprocess ([02](02-architecture.md)). There is nothing else to launch, and no ordering to remember.

## Backup and moving machines

The whole system is one directory plus keychain items. Say what moves and what doesn't:

| Moves with `~/.dreamjob/` | Doesn't move |
| --- | --- |
| Database, profile, answers, sources, sites, accounts registry | Site passwords and the mailbox token (keychain) |
| Applications, artifacts, mail, logs | Browser sessions — they're in the tree but tied to the old machine's browser build |
| | The pairing token — re-pair the phone |

So a restore leaves you logged out of employer systems and unpaired, with every application and artifact intact. That is the right trade: the irreplaceable things are the records of what you sent, and sessions are cheap to rebuild.

**`~/.dreamjob/` is gitignored and must never be committed** ([09](09-compliance.md)). Back it up with `rsync` to somewhere you control, never to a sync service — it holds a resume, a mailbox, and a map of every job you've applied to.

## Failure modes at startup

| Symptom | Cause | Response |
| --- | --- | --- |
| Refuses to start, names a file and line | Invalid config | Fix the file; never a partial boot |
| Refuses to bind | `bind:` is a public interface without `--allow-public` | Intentional ([09](09-compliance.md)) |
| Starts, deck is empty, no error | `sources.yaml` empty or every posting filtered | `dreamjob deck --explain` prints filter failures per posting |
| Starts, tailoring fails | No `ANTHROPIC_API_KEY`, no Claude Code | Ingestion and matching still work; the queue holds |
| App can't connect | Wrong interface, TLS not trusted, expired pairing | `dreamjob pair --again`; the app must say which of the three it hit |
| Core subprocess not found | `dreamjob-core` not on `PATH` or version-skewed | Hard error at boot, not at first use — a contract mismatch discovered mid-ingest is worse ([18](18-api-contract.md)) |

## Open questions

- Is `dreamjob` one binary with subcommands, or a `dreamjob-server` daemon plus a thin CLI client that talks to it over the same API the app uses? The second is more honest — the CLI becomes the API's first consumer and keeps it eating its own dogfood.
- Should `init` interactively build `profile.yaml` by asking, or write a commented template to edit? The template is faster to iterate on; the wizard is what makes the first ten minutes not feel like homework.
- Does `sources.yaml` deserve board *discovery* ("find the Greenhouse token for stripe.com"), or does the user paste tokens? Discovery is a small scraper with its own [09](09-compliance.md) obligations.
- Config lives in YAML for consistency with the files the skills already produce. Go and Rust both prefer TOML. Is consistency across the seven files worth it, or should `config.yaml` be `config.toml` and match its readers?
- Backing up browser sessions is technically possible and probably a bad idea. Confirm it stays out.
