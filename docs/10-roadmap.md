# 10 — Roadmap

**Status: specified.** M0 is done; M1 has not started.

Milestones are ordered by dependency, not by appeal. Each lands something usable on its own — the system should be worth running at every stage, not only at the end.

## M0 — Resume skills ✅ done

Four Claude Code skills sharing state through `resume-workspace/`.

**Shipped:** `resume-diagnoser`, `resume-recruiter` (modes A and B), `resume-rewriter`, `resume-hiring-manager`; the shared-state contract; the no-invented-metrics rule.
**Spec:** [08](08-resume-skills.md).

## M1 — Aggregator

One source end to end.

**Scope:** the workspace layout — `dreamjob-server` (Go), `dreamjob-core` (Rust), `dreamjob-app` (Flutter, empty for now), `contract/`; the `SourceAdapter` interface; a Greenhouse adapter; the normalizer in the core (steps 1–7 of [04](04-aggregation.md)); fingerprint + fuzzy dedup; the SQLite store with raw payload retention; the Go↔core subprocess boundary and its JSON Schema; the scheduler; quarantine.

**Acceptance**
- [ ] A configured list of Greenhouse boards ingests into `JobPosting` rows.
- [ ] Re-running ingestion creates zero duplicate postings and updates `last_seen_at`.
- [ ] A posting cross-posted on two configured boards produces one row with two `sources[]` entries.
- [ ] `normalizer_version` bump re-normalizes from stored raw with no network calls.
- [ ] A deliberately malformed payload lands in quarantine and the run completes.
- [ ] Work mode, seniority, comp, and stack extraction hit ≥ 90% agreement with hand-labels on a 100-posting fixture set.
- [ ] Rate limits enforced by the Go runner and observable in logs.
- [ ] `dreamjob-core normalize` runs from a shell against a stored raw payload and produces the same `JobPosting` the server got — the core is testable without the server.
- [ ] The core makes no network call and reads no clock; time is an input. Verified by a test that passes a fixed timestamp and asserts a byte-identical result on two runs a day apart.
- [ ] Every tri-state field survives the round-trip through Go without a zero-value coercion, verified by a fixture where `visa_sponsorship` is absent and must stay absent.

**Deliberately out:** every other source, any UI. Ingestion is inspectable via SQL at this stage, and that is enough.

## M2 — Preferences + matcher

**Scope:** the `Profile` schema and its YAML loader; hard filters; the seven scoring components; thresholds; `reasons[]` generation; the labelled fixture corpus and the precision/recall harness.

**Acceptance**
- [ ] `profile.yaml` loads, validates, and reports errors with line numbers.
- [ ] Every hard filter has a test including its unknown-value case.
- [ ] Scores are reproducible: same inputs, same score, same reasons.
- [ ] Every scored posting produces ≥ 3 human-readable reasons.
- [ ] Against 200 hand-labelled postings: precision ≥ 0.7, recall ≥ 0.8 at threshold 60. Recall is weighted higher — a missed job is invisible, a bad card costs two seconds.
- [ ] A profile edit bumps `version` and invalidates rather than mutates existing `Match` rows.
- [ ] `work_mode_conflict` caps the score at 70 and appears in reasons.

**Usable as:** a CLI that prints today's ranked matches. Worth running by itself.

## M3 — Swipe UI

**Scope:** the local JSON API and its OpenAPI contract; the Flutter macOS app ([11](11-frontend.md)) — design tokens, the card layout of [06](06-swipe-ui.md), keyboard/touch/mouse input, swipe persistence, undo, deck lifecycle including empty/thin/fat states, and the end-of-deck summary.

**Acceptance**
- [ ] `DreamJobTokens` exists and no widget contains a raw colour, duration, or font size.
- [ ] Card layout is covered by golden tests keyed to `card_version`; a layout change without a version bump fails CI.
- [ ] The deck holds 120fps on the target machine while a card is being dragged.
- [ ] The app's models are generated from `contract/openapi.yaml` — no hand-written type mirrors a contract type, in any of the three languages ([18](18-api-contract.md)).
- [ ] Pairing works end to end: scan the server's QR code, token stored in `flutter_secure_storage`, subsequent launches reconnect without re-scanning.
- [ ] The app runs on a **real Android device** on the same network, not just the emulator.
- [ ] Every gesture has a working on-screen button equivalent.
- [ ] Server unreachable: cached deck renders, swipes queue locally and replay on reconnect, and the offline state is visibly distinct from an empty deck.
- [ ] Every swipe writes a `SwipeEvent` with `dwell_ms` and `card_version`.
- [ ] Undo restores the card and appends a compensating event; nothing is deleted.
- [ ] Closing mid-deck and reopening resumes at the same position.
- [ ] An empty deck is visually distinct from a failed sync.
- [ ] Comp provenance, work-mode conflicts, and placeholder warnings all render; none can be suppressed.
- [ ] `MediaQuery.disableAnimations` honoured; no meaning carried by colour alone.
- [ ] The API serves JSON only, binds to the LAN interface, and rejects every request without a valid bearer token — verified by a test that tries.

**Usable as:** the actual product minus applying. Right-swipes queue and the user applies manually from the queue.

## M4 — Tailoring

**Scope:** the apply queue; per-application workspaces; agent invocation (`claude -p` subprocess); the three agent stages; `metrics.md` reuse; the resume artifact chain of [17](17-resume-artifacts.md) — grammar, assembly, PDF render, three-gate verification, content addressing; the review gate and its blocking checks.

**Acceptance**
- [ ] A right-swipe produces a workspace with the posting frozen at swipe time.
- [ ] Recruiter mode A and rewriter run non-interactively to completion, driven from Go, with the existing `SKILL.md` files unmodified.
- [ ] The Anthropic API key never leaves the server — verified by inspecting what the app receives.
- [ ] A resume containing an unfilled placeholder cannot be approved — button disabled, reason shown.
- [ ] Rendered PDFs round-trip through `pdftotext -layout` with no content loss.
- [ ] Every employer, title and date in a rendered resume is byte-identical to the master, enforced by a structured diff rather than by the prompt.
- [ ] Must-land keywords from `keywords.md` are present in the extracted PDF text, or the render fails.
- [ ] A render that fails `resume-diagnoser`'s parse-safety checks cannot be approved.
- [ ] Artifacts are content-addressed; a re-run produces a new hash and the previous file survives.
- [ ] The review screen diffs tailored against master with changed bullets highlighted.
- [ ] Company/role mismatch between artifacts and posting blocks approval.
- [ ] A dealbreaker surfaced by the recruiter halts the application at `needs_attention`.
- [ ] A failed stage retries twice, then halts with the workspace intact.
- [ ] 10 real applications tailored end to end, all reviewed by a human, zero fabricated claims.

**Usable as:** the full product with a manual send. This is the milestone where dreamJob is actually worth using daily.

## M5a — Accounts, mailbox, and the AnswerBook

The prerequisites for applying anywhere that isn't an API. Independently useful: the `AnswerBook` alone removes the most tedious part of applying by hand.

**Scope:** the `AnswerBook` and its editor in the app; the credential vault over the OS keychain; `SiteAccount` and the account registry; email aliasing; the Gmail OAuth flow and scoped queries; verification challenges (email by regex, SMS by push to the phone); the LinkedIn data-export importer.

**Acceptance**
- [ ] `answers.yaml` loads, validates, and every EEO field defaults to `decline`.
- [ ] No password, session cookie, or OAuth token is present anywhere in `dreamjob.db` — verified by a test that greps the schema and a dump.
- [ ] A generated password is written to the keychain and never appears in a log, a prompt, or a transcript.
- [ ] With no keychain available, the system refuses to store credentials and marks affected sites `manual-only`.
- [ ] Mailbox access uses `gmail.readonly`; a test asserts no send or full-access scope is ever requested.
- [ ] Every mailbox query is logged and its sender allowlist is derivable from existing applications.
- [ ] An email verification code is extracted by regex, used once, and never persisted.
- [ ] A magic link whose host differs from the run's domain is refused.
- [ ] An SMS challenge reaches the phone, names the requesting domain, expires at 5 minutes, and the code is never stored.
- [ ] No flow added by M5a requires the server's display: registration approval, challenges, unanswered questions and account management all complete in the app.
- [ ] Disconnecting the mailbox deletes the stored messages and the token together.

## M5b — Submission

**Scope:** API submission adapters for tier-1 sources; the browser sidecar and the recipe system; the site registry; the submit gate; two-signal confirmation; the manual-draft path; idempotency; the submission rate limit; receipt and trace archival.

**Acceptance**
- [ ] Greenhouse API submission works against a real posting, receipt stored.
- [ ] A dry run fills a real Workday form end to end and submits nothing.
- [ ] The sidecar refuses a submit action without a valid single-use human token — verified by a test that tries.
- [ ] The sidecar binds `127.0.0.1` only; a LAN connection attempt is refused.
- [ ] Field read-back verification fails the run on any mismatch, before the gate.
- [ ] A resume uploaded through a Greenhouse candidate profile is verified by filename and hash to be the tailored artifact, not the account's stored resume.
- [ ] A CAPTCHA halts the run and is never solved programmatically.
- [ ] An unmappable required field halts with the question quoted and writes the user's answer back to `answers.yaml`.
- [ ] The model never emits a form value — only `AnswerBook` keys. Verified by the plan schema rejecting literals.
- [ ] Passwords are scrubbed from every archived Playwright trace.
- [ ] The entire submit flow — screenshot, field table, filename check, tap to submit — is completable from the phone with the server headless in another room.
- [ ] A submit with neither confirmation signal lands in `submit_unverified` and is never auto-retried.
- [ ] A submit failure never auto-retries; status and apply URL surfaced.
- [ ] Duplicate detection blocks a second application to the same role within 90 days.
- [ ] The 5/hour cap holds for browser submissions identically to API ones.
- [ ] The browser agent refuses to run against a domain with no site-registry entry.
- [ ] Sources with neither an API nor a recipe produce a prefilled draft and `awaiting_manual_submit`.
- [ ] The submitter refuses any application lacking `approved_at`, verified by a test that tries.
- [ ] No adapter and no recipe exists for LinkedIn or Indeed, and "Apply with LinkedIn" buttons are declined in favour of the real form.

## M6 — Tracking

**Scope:** the application archive; status transitions; follow-up reminders; outcome recording, manual and mailbox-driven; attribution and classification ([16](16-mailbox.md)); baseline reply-rate measurement.

**Acceptance**
- [ ] Every submitted application is queryable by company, role, date, and status.
- [ ] Follow-up reminders fire at +7 and +14 days; auto-close at +30.
- [ ] Outcomes are recordable in under 10 seconds each, by hand, with no mailbox connected.
- [ ] Plus-tagged aliases attribute inbound mail to an application exactly; weak matches are suggested, never applied.
- [ ] Classification is rules-first; the model sees one already-attributed message at a time and nothing else.
- [ ] Every classification is reversible in one tap, and the correction is what gets stored.
- [ ] Messages matching no application are counted and discarded, not retained.
- [ ] Reply rate is computed and reported, establishing the baseline [01](01-product-spec.md) needs.
- [ ] The exact files sent are retrievable by hash for any past application, along with the browser trace where one exists.

## M7 — Learning

**Scope:** feature extraction from swipe history; the logistic regression; the learned scoring component; the coefficient inspector; exploration; reset.

**Acceptance**
- [ ] No learned adjustment applies below 100 swipes.
- [ ] The learned weight is capped at 0.20 even if the profile sets it higher.
- [ ] Every learned adjustment appears in `reasons[]` in user language.
- [ ] Coefficients are viewable and individually vetoable.
- [ ] Reset clears the model without touching the profile.
- [ ] Exploration re-injects cards from categories driven to zero exposure.
- [ ] Precision improves against the M2 baseline on a held-out swipe set, with recall not dropping.

## Course sequencing

All seven milestones are in scope. Worth saying once and then not repeating: M1–M7 is a lot of surface for one term, and the risk is not that any single milestone is hard — it is that M5b (real submissions to real employers) and M7 (a learning loop that needs outcome data) both depend on wall-clock time the term may not contain. Sequence accordingly:

| Phase | Milestones | Why here |
| --- | --- | --- |
| Early | M1, M2 | Go plus a pure Rust core, no UI, fully testable. Fastest path to something demonstrable via CLI output — and the two milestones where the language split pays for itself. |
| Middle | M3, M4 | The two that carry the demo. M4 can be built against a hand-written posting file in parallel with M3 — do that; it's the highest-risk piece. |
| Late | M5a, M5b, M6 | M5b needs a real posting to submit to; M6 needs applications that have aged. Start M6's schema early even if the data is thin. |
| Last | M7 | Needs M6's outcome data to be honest. If the term runs out, ship it trained on swipe history alone and **say so** — an honest limitation documented is worth more than a learning loop that optimizes for the wrong signal. |

Two things to start early regardless of milestone order, because both are slow and neither is on the critical path: the 200-posting labelled corpus M2 needs, and a real Android device you can deploy to.

**M5b is the milestone most likely to be cut, and it should be cut before M4 or M6.** The browser agent is the largest single piece of new surface in the project — a second runtime, per-site recipes that rot, accounts, verification challenges — and its entire payoff is saving the user 30 seconds per application. Manual send already works. If the term compresses, ship M5a (which is genuinely valuable alone: the `AnswerBook` and mailbox tracking) and one API submission adapter, and leave the browser agent specified but unbuilt. That is a better project than a half-working form filler.

## Sequencing notes

- **M1 → M2 → M3 is strictly ordered.** Nothing to match without postings; nothing to swipe without a deck.
- **M4 depends on M3 only for the trigger.** The tailoring pipeline can be built and tested against a hand-written posting file in parallel, and probably should be — it is the highest-risk piece.
- **M5 is optional for a long time.** Manual send costs the user 30 seconds and removes an entire class of catastrophic failure. Do not rush it.
- **M5a before M5b, strictly.** The browser agent cannot register accounts without the vault, cannot pass verification without the mailbox, and cannot fill a form without the `AnswerBook`. Building it first produces a demo that works on exactly one site.
- **M5a is worth shipping alone.** Mailbox-driven tracking is most of M6's value, and the `AnswerBook` pays for itself on manual applications.
- **M6 before M7.** Learning without outcome data optimizes for swipe behaviour rather than for getting hired, which is the wrong objective and a subtle one to notice.

## Explicit non-milestones

Not planned, and not on the backlog: LinkedIn or Indeed automation of any kind, including Easy Apply ([09](09-compliance.md), [15](15-accounts-identity.md)); CAPTCHA solving or any anti-bot evasion; unattended submission (no human clicking) — unspecified and gated behind conditions in [14](14-browser-agent.md) rather than scheduled; sending email as the user; automated password rotation across employer systems; multi-user or hosted deployment; interview scheduling; salary negotiation; any bulk-apply mode.
