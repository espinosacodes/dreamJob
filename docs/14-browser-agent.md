# 14 — Browser agent

**Status: specified.** M5b. Depends on [15](15-accounts-identity.md) for accounts and [17](17-resume-artifacts.md) for the file it uploads.

Most jobs cannot be applied to over an API. Greenhouse, Lever, Ashby and Workable publish application endpoints; the rest of the market — Workday, iCIMS, SuccessFactors, Taleo, Greenhouse boards with custom question sets, and every company career page with a hand-rolled form — exposes a web form and nothing else. Restricting dreamJob to API-submittable sources throws away most of the deck.

The browser agent applies to those. It drives a real browser, as the user, with the user's own sessions, and hands control back to a human at every point where a machine should not be deciding.

## What this is not

This is the section that keeps the rest of the doc honest, so it goes first.

- **Not headless-stealth automation.** No fingerprint randomization, no user-agent spoofing, no CAPTCHA solving, no proxy rotation. Those rules from [09](09-compliance.md) survive unchanged. If a site blocks the browser agent, it succeeded and the application falls back to a manual draft.
- **Not a volume unlock.** The 5/hour submission cap and the ~20 applications/week bar in [01](01-product-spec.md) apply identically to browser submissions. "So we don't get rate-limited by APIs" is a coverage argument, not a throughput argument — it widens *which* jobs are reachable, not *how many* get sent.
- **Not LinkedIn or Indeed.** Easy Apply stays excluded ([09](09-compliance.md), [15](15-accounts-identity.md)). The browser agent's site allowlist has no entry for either, and adding one is a policy change, not a config change.
- **Not unattended through M6.** Every submit is pressed by a human or explicitly authorized by one per application.

## Engine and process shape

**Playwright, driven by a sidecar over localhost.** Dart has no maintained Playwright binding and browser automation is the single worst fit for Dart's ecosystem ([02](02-architecture.md) already concedes this for scraping and PDF extraction). The pattern is the one [07](07-apply-pipeline.md) §2C already established for the LangGraph sidecar: a small local service, a JSON contract, and a Dart side that knows a URL and nothing else.

```
dreamjob_server (Dart)
   │  POST http://127.0.0.1:8765/run   { applicationId, plan }
   │  GET  /run/:id/events (SSE: progress, screenshots, challenges)
   ▼
browser-sidecar (Node + Playwright)
   │  persistent browser context per site profile
   ▼
employer ATS / career page
```

Rules on the sidecar:

- Binds `127.0.0.1` only. It holds live logged-in sessions to employer systems; it is never reachable from the LAN, unlike the JSON API ([09](09-compliance.md)).
- Started and stopped by the Dart server as a child process. A crashed sidecar fails the application to `needs_attention`; it never leaves an orphaned browser holding a half-filled form.
- **Headed by default**, but the browser window is not a UI surface. The product's only UI is the Flutter app ([11](11-frontend.md)); the browser is headed so that screenshots are real and so a human physically at the server *can* take over, not because anyone is expected to be watching it. Headless is allowed only for the dry-run mode below, never for a run that will submit.
- One `BrowserContext` per site profile, backed by a persistent `user-data-dir` under `~/.dreamjob/browser/<profile>/`, so a session survives across applications and the user logs in once per employer tenant rather than once per application.
- Hard ceilings per run, enforced by the sidecar and not by the plan: 10 minutes wall clock, 40 navigations, 200 actions. Exceeding any of them aborts to `needs_attention` with the trace kept.

## Deterministic first, model second

The expensive failure mode is a model confidently typing the wrong thing into a form that goes to an employer. The mitigation is to keep the model out of the loop wherever a selector will do.

Three tiers, tried in order:

| Tier | Mechanism | Used for |
| --- | --- | --- |
| 1 — **Recipe** | A checked-in YAML per ATS platform: selectors, field order, known question texts, the confirmation signal | Greenhouse, Lever, Ashby, Workable embedded forms, Workday — the ~6 platforms that cover most postings |
| 2 — **Semantic map** | Accessibility-tree snapshot → model maps each unfilled field to an `AnswerBook` key, returning `{fieldRef, answerKey}` pairs. The model chooses *mappings*, never *values* | Custom career pages, recipe drift, unexpected extra questions |
| 3 — **Human** | Screenshot to the review screen, the user fills the remainder in the live browser or the app | Anything tier 2 declines, plus every CAPTCHA and every consent checkbox |

A recipe that stops matching is quarantined the same way a source adapter is ([02](02-architecture.md)): the platform drops to tier 2 for that run, the mismatch is logged with a screenshot, and the recipe is flagged for review rather than silently patched by the model.

**The model never emits a value.** It returns a key into the `AnswerBook`; the sidecar resolves the key to a string and types it. This is what makes "the agent invented a salary expectation" structurally impossible rather than prompt-dependent.

```yaml
# recipes/greenhouse.yaml
match:
  urlPattern: "^https://(job-)?boards\\.greenhouse\\.io/"
  requiredSelector: "#application_form"
fields:
  - selector: "#first_name"        answer: identity.firstName
  - selector: "#last_name"         answer: identity.lastName
  - selector: "#email"             answer: identity.email
  - selector: "#phone"             answer: identity.phone
  - selector: "#resume"            upload: artifact.resumePdf
  - selector: "#cover_letter"      upload: artifact.coverLetterPdf   optional: true
questions:
  matchBy: labelText               # custom questions vary per employer
  fallback: tier2
submit:
  selector: "#submit_app"
  guard: humanConfirm              # see §5
confirmation:
  anyOf:
    - urlContains: "confirmation"
    - textMatches: "(?i)thank you for applying|application (was )?submitted"
```

## The AnswerBook

Every ATS asks the same forty questions. The user answers each one **once, ever** — the same principle as `metrics.md` in [07](07-apply-pipeline.md), applied to form fields.

`~/.dreamjob/answers.yaml`, user-owned and human-editable:

```yaml
identity:      { firstName, lastName, email, phone, addressLine1, city, country, postalCode, linkedinUrl, githubUrl, portfolioUrl }
authorization: { workAuthorizedIn: [CO, ES], requiresSponsorshipIn: [US, CA], visaStatus }
logistics:     { noticePeriodDays: 30, earliestStartDate, willingToRelocate: false, remoteOnly: true }
compensation:  { expectation: { amount, currency, period }, disclosePolicy: rangeOnly | exact | decline }
history:       { referredBy: null, previouslyEmployedHere: false, howDidYouHear: "Company careers page" }
voluntary:     { gender: decline, race: decline, veteranStatus: decline, disabilityStatus: decline }
freeform:      { whyThisCompany: fromCoverLetter, additionalInfo: null }
```

Hard rules:

1. **EEO and voluntary self-identification default to `decline`.** These are protected-characteristic questions with legal weight, they are voluntary by law in every jurisdiction that mandates them, and a model MUST NOT select an answer for them under any circumstance. The user may set real values; the model may never infer or change one.
2. **An unmapped required field is not a guess.** If tier 2 cannot map a required field to an existing key with high confidence, the run halts at `needs_attention`, quoting the question verbatim. The user answers it in the app, the answer is written back to `answers.yaml` under a new key, and the run resumes. Question N+1 is free forever after.
3. **`compensation.expectation` is never inferred from the posting.** If the form requires a number and the user has not set one, that is a halt, not an estimate.
4. **`freeform.whyThisCompany` resolves to the cover letter's first paragraph** ([07](07-apply-pipeline.md) stage 3), so free-text boxes get the reviewed text rather than a fresh unreviewed generation mid-run.
5. **Never fill a field the plan did not declare.** Payment fields, "apply on behalf of", and anything matching a credential pattern outside a declared login step are refused outright.

## The run

```
plan ──> navigate ──> [login? 15] ──> fill ──> upload ──> verify ──> HUMAN ──> submit ──> confirm ──> archive
                          │              │                   │          │                    │
                          └─ challenge   └─ tier2/tier3      └─ diff    └─ gate               └─ two-signal
                             (16)           escalation          check      (§5)                  check
```

**Plan.** Dart builds it from the recipe + the application: target URL, artifact paths, the account to use, and the expected confirmation signal. The plan is data; the sidecar executes it. A plan with no `humanConfirm` guard is rejected by the sidecar before the browser opens.

**Dry run.** Every new site is first executed with `submit.enabled = false`: fill everything, screenshot, archive, do not press submit. This is how a recipe gets written and how the user sees — on their phone, from the archived screenshots — what would have been sent. Dry runs may be headless; they are the only runs that may.

**Everything a run produces is phone-consumable.** Screenshots, the field table, the halt reason, the quoted question. A run that can only be understood by looking at the live browser is a run that has failed to report itself, and that is a bug in the sidecar rather than a reason to sit at the server.

**Verify before the gate.** After filling, the sidecar reads every field back out of the DOM and diffs it against the intended values. A field that did not take the value it was given (masked inputs, JS-controlled selects, autocompletes that rewrote the entry) fails the run rather than being submitted with whatever the widget decided.

**Archive.** Every run writes into the application workspace ([07](07-apply-pipeline.md) §1):

```
applications/<id>/browser/
  plan.json           # what was intended
  filled.json         # field → final DOM value, post-verification
  trace.zip           # Playwright trace: DOM, network, actions
  step-*.png          # screenshot per step
  confirmation.png    # the confirmation page
  confirmation.html
```

The trace is what makes "what exactly did it send" answerable six months later. It contains the full resume and the answers, so it lives under the same privacy rules as everything else in the tree ([09](09-compliance.md)).

## The submit gate

The review gate in [07](07-apply-pipeline.md) §5 approves *content*. This gate approves *the actual form*, and they are not the same check — the content can be perfect and the form still have dropped the resume upload or mangled the phone field.

Through M6, the click is human — and **the human is on their phone**. The product's UX lives entirely in the Flutter app; the server, the sidecar and the browser are back-end machinery the user never has to be sitting in front of.

| Mode | Flow | Used for |
| --- | --- | --- |
| **Assisted — the default** | The app shows the final screenshot plus the `filled.json` table on the phone. The user reviews and taps **Submit** there; the sidecar clicks. Works from anywhere on the LAN, with the server headless in another room | Every submission, including the first to a new site |
| **Attended — the escape hatch** | The headed browser is handed to a human physically at the server, who finishes by hand. Reached by **Fix in browser** on the gate screen, or automatically on a tier-3 halt | CAPTCHAs, identity checks, and anything the phone can't resolve |

Assisted is the default because the alternative quietly makes a desktop presence a product requirement, and it isn't one. Attended exists because some halts genuinely cannot be resolved through a screenshot — and when the user isn't at the machine, those applications simply wait as `needs_attention` or fall back to a manual draft. **Waiting is an acceptable outcome; requiring the user at a desk is not.**

The sidecar will not click a submit control unless it holds a confirmation token minted by the Dart server against a specific `applicationId`, valid for 10 minutes, single use. There is no code path from "form is filled" to "form is submitted" that does not pass through a human. `approved_by` stays `'human'` ([03](03-data-model.md)).

**Unattended submission is an M7+ question and is not specified here.** If it ever ships it requires: a green recipe, N prior successes on that exact recipe version, no tier-2 mapping used in the run, no free-text field, and an explicit per-site opt-in. Anything less and the failure mode is a wrong application sent to a real employer with no one watching.

## Confirmation

A submitted form that we cannot prove was submitted is worse than a failure, because the user will not re-apply.

Two independent signals are required for status `submitted`:

1. The confirmation signal from the recipe — URL pattern or page text — captured as a screenshot.
2. A confirmation email in the mailbox ([16](16-mailbox.md)) from the employer's ATS domain within 15 minutes.

| Signals | Status | Behaviour |
| --- | --- | --- |
| Both | `submitted` | Normal path |
| Page only | `submitted`, `confirmationEmail: missing` | Recorded, surfaced in the tracker; many ATS genuinely don't email |
| Email only | `submitted` | The email is the stronger signal |
| Neither | `submitUnverified` | **Never auto-retried.** Surfaced with the trace and the apply URL; the user decides |

`submitUnverified` exists specifically because a duplicate application is worse than a missed one ([07](07-apply-pipeline.md)), and a blind retry after an ambiguous submit is the most likely way to send one.

## Failure modes

| Failure | Response |
| --- | --- |
| CAPTCHA / bot challenge | Halt immediately. Attended: the user solves it and the run continues. Assisted: `needs_attention`. **Never** solved programmatically or outsourced |
| Login required, no account | Hand to [15](15-accounts-identity.md); registration is its own flow, not a step inside the apply run |
| Email or SMS verification | Hand to [16](16-mailbox.md) / [15](15-accounts-identity.md); status `awaitingVerification`, run parked up to 15 min |
| Required field unmappable | `needs_attention` with the question quoted; answer written back to `answers.yaml` |
| Field read-back mismatch | Fail the run before the gate; never submit a form we can't describe |
| Resume upload rejected (format/size) | Re-render per [17](17-resume-artifacts.md) in the accepted format, retry the upload once, then halt |
| Posting closed / form 404 | `abandoned` with the reason. Don't hunt for a replacement URL |
| Site blocks automation (bot wall, `robots.txt` on the apply path) | Fall back to manual draft permanently for that site; record it in the site registry |
| Sidecar crash or timeout | `needs_attention`, browser context left intact for inspection, trace kept |

Nothing in this table auto-retries a submit. Retries are for fills, navigations, and renders.

## Site registry

`~/.dreamjob/sites.yaml` — one entry per apply domain, the browser agent's allowlist. **The agent will not run against a domain with no entry.**

```yaml
- domain: boards.greenhouse.io
  recipe: greenhouse
  status: green            # green | dry-run-only | manual-only | blocked
  account: none            # none | required (see 15)
  submits: 14
  lastSuccess: 2026-07-30
  termsReadAt: 2026-06-02
  notes: "Custom question sets vary per employer; tier 2 handles them."
```

`status: manual-only` and `blocked` are sticky: once a site has blocked us or forbidden automation in its terms, only a human edit moves it back, and the reason is recorded. Promotion to `green` requires a successful dry run plus one attended submit.

## Open questions

- Is the sidecar Node + Playwright, or Python + Playwright shared with the LangGraph sidecar in [13](13-practice-tracks.md)? One runtime is less to install; Node is the better-supported Playwright target.
- ~~Is assisted mode actually the default, with attended reserved for new sites?~~ **Resolved:** assisted is the default for everything. The UX is the phone app; attended is a fallback for halts a screenshot can't resolve, and an application that has to wait for the user to reach the server is an acceptable cost.
- Does the phone need a live view of a run in progress (streamed screenshots), or is the final gate screenshot enough? Live is reassuring and is a lot of SSE plumbing for something the user watches once.
- Should recipes live in the repo (shareable, reviewable, but they encode third-party selectors) or under `~/.dreamjob/` (private, but every user rediscovers Workday alone)?
- Workday creates a candidate account per employer tenant, which means dozens of accounts ([15](15-accounts-identity.md)). Is Workday worth supporting at all before that flow is boringly reliable?
- Does a failed read-back verification deserve one automatic re-fill attempt, or is any mismatch immediately human business?
