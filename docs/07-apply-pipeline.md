# 07 — Apply pipeline

**Status: specified.** M4 builds tailoring + the review gate; M5a adds accounts and the mailbox; M5b adds submission.

What happens between a right-swipe and a sent application.

```
right-swipe
   │ 10s undo window
   v
queued ──> tailoring ──> awaiting_review ──> approved ──> submitting ──> submitted
              │  agent      │  human            │            │  │
              │  runs       │  gate             │            │  ├─> submit_unverified
              │             │                   │            │  └─> submit_failed
              │             │                   │            └─> awaiting_verification (15/16)
              │             │                   └─> awaiting_manual_submit
              └─> failed ───┴─> abandoned
```

## 0. Queueing

The right-swipe writes an `Application` in `queued` and freezes the posting text into the workspace. Freezing matters: postings get edited and pulled, and the application must be reviewable against what it was actually written for.

Applications are processed **serially**. Each is an agent run with real cost ending in a human review; parallelism just builds a review backlog.

## 1. Workspace

Each application gets its own directory, which is also the `resume-workspace/` the skills expect ([08](08-resume-skills.md)):

```
applications/<application_id>/
  profile.md              # copied from the global profile — role, industry, seniority
  resume.md               # copied from the master resume text
  diagnosis.md            # copied from the one-time baseline diagnosis, if present
  posting.md              # frozen posting: title, company, URL, full text, requirements
  keywords.md             # written by resume-recruiter (mode A)
  bullets-rewritten.md    # written by resume-rewriter
  cover-letter.md         # written by the cover-letter stage
  resume.pdf              # rendered, the file actually sent — hardlink into artifacts/ (17)
  receipt.json            # submission response
  browser/                # plan, filled fields, trace, screenshots (14)
  transcript-<stage>.jsonl
```

Copying rather than symlinking the master files is deliberate: an application is a permanent record of what was sent, and it must not change when the master resume does.

## 2. How the agent is invoked

The backend is Go, and **an official `anthropic-sdk-go` exists** — so unlike the earlier Dart design there is no forced choice between shelling out and hand-rolling HTTP. Both remaining paths are chosen on merit:

**A — `claude -p` as a subprocess (recommended).** The pipeline spawns Claude Code with the application workspace as its working directory and the skills in [`skills/`](../skills/) on its skills path, then sends the stage prompt. The `SKILL.md` files are reused verbatim — the skills stay the product's differentiator instead of being re-implemented as prompt strings, and the workspace-file contract in [08](08-resume-skills.md) works unchanged because it was designed for exactly this.

```go
cmd := exec.CommandContext(ctx, "claude", "-p", prompt, "--output-format", "json")
cmd.Dir = workspacePath
out, err := cmd.Output()
```

Requires Claude Code installed on the host — acceptable, since the host is the user's own machine.

**B — `anthropic-sdk-go`.** The official SDK: typed requests, streaming, and tool-use with a schema the model must satisfy. Use `claude-opus-5`. This is not merely a fallback — it is the *better* path for any stage whose output is structured rather than prose, which currently means form-field mapping ([14](14-browser-agent.md)), where "return `AnswerBook` keys and nothing else" wants schema enforcement rather than a parsed document.

**C — a LangGraph sidecar.** A small Python service on localhost exposing one endpoint; the Go pipeline POSTs the workspace paths and gets back the artifacts. This is how the multi-agent and model-evaluation work in [13](13-practice-tracks.md) plugs in, and it is why this section is an interface rather than a hardcoded call. The Go side must learn nothing about Python beyond a URL.

Path A is the default for the document-shaped stages and the fallback for everything else. B and C are alternate backends behind the same interface — keeping A working is what makes cross-model comparison possible.

Either way the API key comes from the environment, never from `profile.yaml` ([09](09-compliance.md)).

## 3. Tailoring stages

Three agent runs, in order. Each is a separate invocation, so a failure retries one stage rather than the whole chain.

### Stage 1 — `resume-recruiter` (mode A, targeted)
Input: `posting.md`, `resume.md`, `profile.md`.
Output: `keywords.md` — the top 15 keywords ranked by position in the posting, each marked *present and prominent* / *present but buried* / *absent*, plus any dealbreakers the posting states.

Mode A already exists in the skill and is the mode this pipeline uses. The skill's rule that keywords must be earnable by a true bullet is what keeps this stage from becoming a stuffing machine.

**Abort condition.** If this stage surfaces a dealbreaker that contradicts the profile — clearance required, no sponsorship, a years floor far above the user's band — the application halts at `needs_attention` with the conflict quoted. The matcher should have caught it; when the matcher misses, this is the backstop.

### Stage 2 — `resume-rewriter`
Input: `keywords.md`, `resume.md`, `diagnosis.md`, `profile.md`.
Output: `bullets-rewritten.md` — the experience section rewritten in XYZ form, keywords layered in only where the user's actual work supports them.

**The placeholder rule is the load-bearing one.** The skill never invents a metric; it emits `[X% — verify before sending]`. In interactive use the user answers the batched question. In the pipeline there is no one to ask mid-run, so:

1. Numbers already supplied in a previous application are reused from a shared `metrics.md` in the master workspace — the user answers each question once, ever, not once per application.
2. Anything still unknown stays a placeholder.
3. Placeholders block approval at the review gate ([06](06-swipe-ui.md)). They cannot reach an employer.

### Stage 3 — cover letter
Input: everything above.
Output: `cover-letter.md`. Three paragraphs: why this company specifically (grounded in the posting, not in adjectives), the two most relevant pieces of the user's experience with their evidence, and a close.

Rules: no claim that isn't in the resume; the company name and role title are inserted from structured fields, never typed by the model into prose it might get wrong; no "I am passionate about" opener. If the posting doesn't accept a cover letter, this stage is skipped.

## 4. Rendering

`bullets-rewritten.md` plus the unchanged sections become `resume.pdf`, generated server-side with the `pdf` package. **Full lifecycle — grammar, assembly, DOCX, verification, content addressing — is in [17](17-resume-artifacts.md).** The load-bearing summary:

- Single column. No tables, no text boxes, no headers or footers, no graphics or icons.
- Standard section headings: Experience, Education, Skills, Projects.
- Consistent unambiguous dates in one format throughout.
- Embedded, selectable text — never an image of text.
- A common font.
- Employers, titles and dates are copied from the structured master, never re-typed by a model.
- **Verification:** after rendering, shell out to `pdftotext -layout` and diff the extracted text against the source markdown. Anything that doesn't round-trip fails the render, because `resume-diagnoser` is right that unparseable-by-us means unparseable-by-them. Two further gates — every must-land keyword present in the extracted text, and the diagnoser's parse-safety checks passing — are specified in [17](17-resume-artifacts.md). This chain is the reason PDF generation stays on the server and never moves into the Flutter app.

## 5. Review gate

Mandatory through M6, per application, human only. The screen is specified in [06](06-swipe-ui.md). What the gate enforces:

| Check | Enforcement |
| --- | --- |
| Unfilled `[verify before sending]` placeholders | Blocks approval |
| Company name and role title match the posting | Blocks approval on mismatch |
| PDF round-trip verification passed | Blocks approval |
| Cover letter names the right company | Blocks approval on mismatch |
| User has viewed the rendered resume | Blocks approval |
| Must-land keywords present in the extracted PDF text ([17](17-resume-artifacts.md)) | Blocks approval |

`approved_by` has one legal value: `'human'`. The submitter checks `approved_at` itself rather than trusting the caller.

**This gate approves content, not the form.** Browser submissions pass a second, separate gate at the filled form ([14](14-browser-agent.md) §5) — a perfect resume can still be attached to a form that dropped the upload or mangled the phone field, and one review cannot catch both classes of failure.

## 6. Submission

| Path | When | Behaviour |
| --- | --- | --- |
| API submit | Source adapter has `canSubmit` and a documented application endpoint | POST the application per the source's documented schema; store the response as `receipt.json`; status `submitted` |
| **Browser submit** | No API, but the apply domain is `green` in the site registry and a recipe matches ([14](14-browser-agent.md)) | The sidecar fills the form as the user, a human presses submit, two confirmation signals are required; status `submitted` or `submit_unverified` |
| Manual draft | Everything else — no recipe, `manual-only` sites, tier-3 escalation, anything blocked | Write the prefilled draft, open the apply URL, status `awaiting_manual_submit`; the user confirms when they've sent it |
| Never | LinkedIn / Indeed Easy Apply, or any site whose terms forbid automated applications | No adapter and no recipe exists; the user gets the URL ([09](09-compliance.md), [15](15-accounts-identity.md)) |

Preference order is API → browser → manual. The API path stays first wherever it exists: it is fewer moving parts, it returns a structured receipt, and it cannot mis-click.

Browser submission may require an account at the employer ([15](15-accounts-identity.md)) and an email or SMS verification ([16](16-mailbox.md)). Those are separate runs with their own human gates; the application parks at `awaiting_verification` while they resolve and resumes afterwards.

**Submission rules**

- **Never auto-retry.** A duplicate application is worse than a missed one. On failure: `submit_failed`, keep the receipt, surface the apply URL, let the human decide.
- **Idempotency.** Before submitting, check for an existing `submitted` application against the same `posting_id` or the same company+title fingerprint within 90 days. Applying twice to one role reads as careless.
- **Rate limit.** No more than N submissions per hour (default 5), regardless of queue depth. Ties to the quality bar in [01](01-product-spec.md).
- **Everything archived.** Request, response, and the exact files sent, kept indefinitely.

## 7. Tracking (M6)

After `submitted`:

- Follow-up reminder at +7 days if no response, +14 as a second nudge, then close as `no_response` at +30.
- Outcomes recorded on `Application.outcome`, from the mailbox integration ([16](16-mailbox.md)) or manual entry. Manual entry remains supported forever — the mailbox grant is optional, and the tracker must work without it.
- Outcome data is the highest-value M7 training signal — it's the only measurement of whether tailoring worked.

## Failure modes and responses

| Failure | Response |
| --- | --- |
| Agent stage fails (API error, timeout) | Retry that stage twice; then `needs_attention`, workspace kept |
| Posting closed between swipe and submit | Halt, mark `abandoned` with the reason; don't submit into a dead req |
| Render round-trip fails | Halt at `needs_attention`; a mangled resume is worse than a late one |
| Submit endpoint changed shape | Halt, quarantine the adapter, fall back to manual draft for that source |
| Browser recipe stops matching | Drop to tier 2 for that run, flag the recipe; repeated failures move the site to `manual-only` ([14](14-browser-agent.md)) |
| Form submitted, no confirmation signal | `submit_unverified`. **Never auto-retried** — a blind retry after an ambiguous submit is the likeliest way to send a duplicate |
| Verification challenge expires | `needs_attention`; the browser session is kept so the user can finish by hand |
| User abandons at review | `abandoned`, recorded as a matcher false-positive ([01](01-product-spec.md)) |

## Open questions

- Where does `metrics.md` live — a global user file, or per-employer given that a number's context differs by story?
- Should the pipeline re-run `resume-diagnoser` when the master resume changes, or is that always a manual step?
- Cover letter always, never, or per-posting? Some ATS forms make it optional, and a weak letter can hurt more than no letter.
- ~~For manual-draft sources, is browser automation to *prefill* (not submit) a form acceptable?~~ **Resolved:** yes, and it goes further — prefill plus a human-pressed submit, specified in [14](14-browser-agent.md). The line that matters is the human clicking, not the machine typing.
- Serial processing was chosen when every application ended in one agent run. Browser runs park on verification challenges for minutes; does the queue need to interleave, or does parking simply block the queue and that's acceptable at 20/week?
