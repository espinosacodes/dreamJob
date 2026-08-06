# dreamJob specs

Written specs for the system described in the [root README](../README.md). The README is the pitch; these are the contracts.

**Status.** Only the resume skills exist as code today ([`skills/`](../skills/)). Everything else here is design intended to be built against, not documentation of shipped behaviour. Each doc marks what is **built**, **specified**, or **open**.

| Doc | Covers | Status |
| --- | --- | --- |
| [01 — Product spec](01-product-spec.md) | Problem, users, scope, non-goals, success metrics | Specified |
| [02 — Architecture](02-architecture.md) | Components, data flow, the Go/Rust/Flutter split, failure handling | Specified |
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
| [18 — API contract](18-api-contract.md) | `contract/` as source of truth, endpoints, the Go↔Rust boundary, contract tests | Specified |
| [19 — Configuration & first run](19-configuration.md) | Prerequisites, the seven config files, the ten-step first run, backup | Specified |
| [Appendix — `air` box](server.md) | The deployment machine, and [09](09-compliance.md)'s ruling on running dreamJob there | Ops |

## Stack at a glance

**Go for the service, Rust for the pure core, Flutter for the app.** Go owns anything with a network or a clock in it; Rust owns anything that must be exactly right and touches nothing.

| Piece | Language | Runs on |
| --- | --- | --- |
| `dreamjob-app` | Flutter/Dart, mobile-first (Android primary, iOS secondary) | The user's phone |
| `dreamjob-server` | Go — API, scheduler, ingestion, SQLite, pipeline, vault, mailbox | The user's machine |
| `dreamjob-core` | Rust — normalize, dedup, match, render, verify. A subprocess, not a service | The user's machine |
| `browser-sidecar` | Node + Playwright — from M5b, loopback only | The user's machine |
| `contract/` | OpenAPI 3.1 + JSON Schema — the source of truth for all three | Generated into each |

The phone reaches the server over the LAN with a paired bearer token ([09](09-compliance.md)). The resume, the database, the credentials, and the Anthropic API key never leave the server.

**There is no shared package any more**, and that is the biggest thing this stack gives up: the app↔server contract is no longer compile-checked. `contract/` plus generated types plus contract tests replace it ([18](18-api-contract.md)), and a hand-written struct that mirrors a contract type is a defect.

## Conventions used in these docs

- Type definitions are written in **Rust**, matching `dreamjob-core`, because it is the only one of the three languages that can express the model's rules. They are a reference projection of `contract/`, not the source of truth ([03](03-data-model.md)). Go interfaces are shown in Go where the interface *is* the point.
- **MUST / SHOULD / MAY** carry their RFC 2119 meanings.
- Open decisions are collected under an **Open questions** heading at the end of each doc rather than buried inline.
- Nothing in these docs licenses automating a source whose terms forbid it. See [09](09-compliance.md).
- Contract types are generated from `contract/`, never hand-written. See [18](18-api-contract.md).
