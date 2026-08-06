# 12 — Build guide

**Status: process doc.** Not a spec — this is how the other eleven get turned into code.

You are writing all of it by hand. The specs are the ticket; you are the engineer. This doc says what order to work in, which parts are worth slowing down on because they're the ones that come up in interviews, and where the traps are.

## The rule

**Everything in `dreamjob-server`, `dreamjob-core`, and `dreamjob-app` gets typed by you.** Code you didn't write is code you can't defend when someone asks "walk me through how you did that" — which is exactly what [`resume-hiring-manager`](../skills/resume-hiring-manager/SKILL.md) exists to catch. A project you can't explain is worse than a smaller one you can.

Generated code is fine — `oapi-codegen`, `sqlc`, `serde` derives, the Dart client from the OpenAPI document. That's a compiler, not a shortcut. You still have to be able to explain what it generated and why, and [18](18-api-contract.md) makes generating them mandatory rather than optional: a hand-written mirror of a contract type is the bug this project is most likely to ship.

## Where to start

Don't start at M1 and go in order. Start with the thinnest slice that produces a card on a screen, then widen it.

1. **`JobPosting` in Rust first, nothing else.** One struct, `serde` derives, a JSON round-trip test. It's 40 lines and it forces the first real decision: what's `Option` and why ([03](03-data-model.md) argues for `Unknown` as a variant — make sure you agree before you copy it). Do it in Rust rather than Go precisely because Rust will not let you be vague about it.
2. **A Greenhouse fetch, hardcoded board, printing titles.** No store, no adapter interface. Just prove you can hit the API and parse it.
3. **Store those postings in SQLite from Go.** Write the SQL yourself, generate the accessors with `sqlc`. Now you have a schema, a migration, and a real question: what do you index?
4. **Extract the `SourceAdapter` interface** — after the second source exists, not before. An interface designed against one implementation is a guess.
5. **The matcher in Rust, as a pure function with a test file.** No UI. `cargo test` printing scores is a demo. This is the first place the two-language split earns itself — and the first place you'll want to shortcut it by putting the matcher in Go. Don't; it's the piece with the best test story.
6. **Then the Flutter app**, starting with a static card fed by a hardcoded `JobPosting`.

The instinct to build the app first is strong and wrong. The app is the least interesting part of the system and the most visible, which is a bad combination when you're short on time.

## The parts worth slowing down on

These are the pieces of dreamJob that map onto real interview questions. When you hit one, resist looking anything up for the first 20 minutes.

| Where | The problem | What it's really testing |
| --- | --- | --- |
| Dedup, stage 2 ([04](04-aggregation.md)) | Fuzzy-match two postings by title trigram similarity and description shingles | String similarity, tokenization, threshold tuning, why exact hashing isn't enough. This is the most interview-shaped problem in the whole project. |
| Rate limiting ([04](04-aggregation.md), [09](09-compliance.md)) | Enforce req/min and concurrency in the runner, not the adapter | Token bucket vs leaky bucket, `Stream` backpressure, why the *caller* enforces the limit |
| Ingestion | Stream 900 postings without buffering them | Async iteration, memory profile, where `await for` blocks and where it doesn't |
| Matcher ([05](05-matching.md)) | Weighted scoring over seven components, deterministic and explainable | Pure functions, testability, floating-point comparison, precision/recall tradeoffs against a labelled set |
| Swipe log ([03](03-data-model.md)) | Current deck state = a fold over an append-only event log; undo is a compensating event | Event sourcing in miniature. "Why not just delete the row?" is a question you should have a crisp answer to. |
| Offline replay ([02](02-architecture.md)) | Client-generated IDs so a re-sent swipe is a no-op | Idempotency, at-least-once delivery, why the server can't mint the ID |
| Application status ([03](03-data-model.md)) | A 14-state machine with one-way transitions and a hard gate before `submitting` | Encoding invariants in types vs in checks. Make an illegal transition fail to compile if you can. |
| Apply queue ([07](07-apply-pipeline.md)) | Serial processing, retry with a cap, partial state preserved on failure | Concurrency control, isolates, idempotent retry |
| Deck query | Filter + rank + paginate, fast, on a table that grows | Indexes, query plans, and whether you compute the deck on read or on write |

The Flutter work is craft rather than algorithms — real skill, but it's not what a systems interview probes. Budget accordingly.

## Traps

- **Don't build the abstraction first.** `SourceAdapter`, `DreamJobTokens`, the theme system — all of them are specced, and all of them will be wrong if you write them before you have two concrete cases. The spec describes the destination, not the order.
- **Write the test with the labelled data early.** [05](05-matching.md) wants 200 hand-labelled postings. Labelling is boring and slow and blocks nothing, so it's the first thing to slip and the last thing you'll want to do at 2am. Start it in week one, 20 at a time.
- **Freeze the contract before building the app.** Every `contract/openapi.yaml` change ripples through generated code in three languages. Cheap in week two, expensive in week eight — and unlike the old shared-package design, nothing will fail to compile to warn you. That's what the contract tests in [18](18-api-contract.md) are for.
- **Don't let Go's zero values eat your tri-states.** `Dealbreakers.VisaSponsorship` is `*bool` for a reason ([03](03-data-model.md)). A plain `bool` here compiles, passes tests, and silently drops every posting that didn't mention sponsorship.
- **Get one thing to a real Android device early.** Emulator-only means you find the device problems last.
- **Don't chase M5b.** Real submissions to real employers is the milestone with the least learning per hour and the most ways to embarrass yourself. Manual send costs you 30 seconds, and the browser agent ([14](14-browser-agent.md)) is a second runtime plus per-site recipes that rot — the largest new surface in the project for the smallest per-application saving. M5a (the `AnswerBook`, the vault, the mailbox) is the half worth building.

## Using me on this repo

Useful:

- Reviewing code you wrote — bugs, edge cases, "what would a senior engineer flag here"
- Explaining a concept (how `sqlc` generates what it does, why the borrow checker is rejecting something, what a spring simulation is doing)
- Rubber-ducking a design decision before you commit to it
- Clarifying or amending these specs
- Mock interviews on the code you've written — that's what [`resume-hiring-manager`](../skills/resume-hiring-manager/SKILL.md) is for, and this project is the best material you'll have

Not useful, by your own rule:

- Writing implementation files
- Filling in a function body you're stuck on — ask for the approach instead, then type it
- Debugging by handing me the error and taking the patch back. Say what you think is wrong first; I'll tell you if you're right.

Scaffolding (`go mod init`, `cargo new`, `flutter create`, the workspace layout) is a grey area. Ask if you want it.

## The check that matters

Every few weeks, pick a piece you built and answer out loud:

1. What does it do, in two sentences, to someone who hasn't seen the code?
2. Why this approach and not the obvious alternative?
3. What breaks it? What's the input you'd be nervous about?
4. What would you do differently with another week?

If any answer is mushy, that's the part to revisit — not because the code is wrong, but because you can't yet sell it. Run [`resume-hiring-manager`](../skills/resume-hiring-manager/SKILL.md) against your dreamJob bullets once you have a few; it'll push on exactly these.
