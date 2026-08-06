# dreamJob specs

Written specs for the system described in the [root README](../README.md). The README is the pitch; these are the contracts.

**Status.** Only the resume skills exist as code today ([`skills/`](../skills/)). Everything else here is design intended to be built against, not documentation of shipped behaviour. Each doc marks what is **built**, **specified**, or **open**.

| Doc | Covers | Status |
| --- | --- | --- |
| [01 — Product spec](01-product-spec.md) | Problem, users, scope, non-goals, success metrics | Specified |
| [02 — Architecture](02-architecture.md) | Components, data flow, the all-Dart stack, failure handling | Specified |
| [03 — Data model](03-data-model.md) | `JobPosting`, `Profile`, `Match`, `SwipeEvent`, `Application` | Specified |
| [04 — Aggregation](04-aggregation.md) | Source adapters, normalization, dedup, scheduling | Specified |
| [05 — Matching](05-matching.md) | Hard filters, scoring, thresholds, explanations, learning | Specified |
| [06 — Swipe UI](06-swipe-ui.md) | Card anatomy, interactions, deck lifecycle | Specified |
| [07 — Apply pipeline](07-apply-pipeline.md) | Per-application agent run, review gate, submission | Specified |
| [08 — Resume skills](08-resume-skills.md) | The four skills, their shared state contract | Built |
| [09 — Compliance & privacy](09-compliance.md) | Source terms, rate limits, PII, honesty rules | Specified |
| [10 — Roadmap](10-roadmap.md) | M1–M7 with acceptance criteria | Specified |
| [11 — Frontend (Flutter)](11-frontend.md) | Platform targets, app structure, design tokens, motion, the design-reference list | Specified |
| [12 — Build guide](12-build-guide.md) | Build order, the interview-shaped problems, traps, how to use Claude here | Process |
| [13 — Practice tracks](13-practice-tracks.md) | LangGraph multi-agent + model evals, algorithms, SQL | Process |
| [14 — Browser agent](14-browser-agent.md) | Applying through web forms: the Playwright sidecar, recipes, the `AnswerBook`, the submit gate | Specified |
| [15 — Accounts & identity](15-accounts-identity.md) | Registering at employer ATS, the credential vault, email aliases, SMS verification, LinkedIn, Greenhouse candidate accounts | Specified |
| [16 — Mailbox](16-mailbox.md) | Gmail/IMAP: verification codes and outcome detection, and the privacy posture both need | Specified |
| [17 — Resume artifacts](17-resume-artifacts.md) | Master PDF in, tailored PDF/DOCX out: grammar, assembly, rendering, three-gate verification | Specified |

## Stack at a glance

**Dart end to end.** A Flutter app on the phone, a `shelf` backend on the user's machine, and a shared package holding the models so the two cannot drift.

| Piece | Package | Runs on |
| --- | --- | --- |
| `dreamjob_app` | Flutter, mobile-first (Android primary, iOS secondary) | The user's phone |
| `dreamjob_server` | Dart + `shelf` + `drift` (SQLite) | The user's machine |
| `dreamjob_shared` | `freezed` models — the API contract | Both |
| `browser-sidecar` | Node + Playwright — the one deliberate exception, from M5b | The user's machine, loopback only |

The phone reaches the server over the LAN with a paired bearer token ([09](09-compliance.md)). The resume, the database, the credentials, and the Anthropic API key never leave the server. There is no official Anthropic Dart SDK, so the tailoring agent runs `claude -p` as a subprocess or calls the Messages API over raw HTTP ([07](07-apply-pipeline.md)). There is no maintained Dart Playwright binding either, which is why [14](14-browser-agent.md) is a sidecar behind a JSON boundary rather than more Dart.

## Conventions used in these docs

- Type definitions are written in Dart, matching `dreamjob_shared`. Classes are shown plainly; the real ones use `freezed`.
- **MUST / SHOULD / MAY** carry their RFC 2119 meanings.
- Open decisions are collected under an **Open questions** heading at the end of each doc rather than buried inline.
- Nothing in these docs licenses automating a source whose terms forbid it. See [09](09-compliance.md).
