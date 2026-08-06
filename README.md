# dreamJob

Swipe through every job that actually matches you, and let an AI agent tailor your resume to each one before it applies.

> **Status: early.** The resume-tailoring brain exists today as four Claude Code skills in [`skills/`](skills/). The aggregator, the swipe UI, and the apply pipeline are not built yet. Everything below the "How it works" heading is the plan, not shipped software.
>
> Full specs — data model, matching, apply pipeline, compliance — are in [`docs/`](docs/).
>
> **Stack:** Dart end to end — a Flutter app on your phone, a `shelf` backend on your machine, shared models between them.

## The problem

Applying to jobs is three chores stacked on top of each other:

1. **Finding them.** Postings are scattered across LinkedIn, Indeed, and thousands of company boards. The aggregators that do exist bury remote/hybrid/onsite filters and lie about location.
2. **Deciding.** Reading a full job description to learn it's onsite in another country is a 90-second tax, paid hundreds of times.
3. **Tailoring.** A generic resume gets screened out. Rewriting it per application is the step everyone skips, and it's the step that decides the outcome.

dreamJob collapses all three into a swipe.

## How it works

```
┌─────────────┐    ┌──────────┐    ┌────────────┐    ┌─────────┐
│  Aggregate  │ -> │  Match   │ -> │   Swipe    │ -> │  Apply  │
└─────────────┘    └──────────┘    └────────────┘    └─────────┘
  pull postings     score against    tinder-style      agent tailors
  from many         your prefs,      deck, one card    resume + cover
  sources           drop the rest    per job           letter, submits
```

**1. Aggregate.** Poll job sources on a schedule, normalize every posting into one shape (title, company, work mode, location, comp, seniority, stack, apply URL), and deduplicate — the same role gets cross-posted five places.

**2. Match.** Score each posting against your preferences and discard anything below the bar, so the deck stays short enough to actually finish.

**3. Swipe.** One card per job: title, company, comp, work mode, location, and the three bullets that matter. Swipe right to apply, left to skip. Swiping left is training data — the matcher learns what you keep rejecting.

**4. Apply.** For every right-swipe, an agent reads the job description, tailors your resume to it, renders an ATS-safe PDF, drafts a cover letter, and submits — through the platform's API where one exists, otherwise by filling the employer's own web form in a real browser and handing you the submit button. Each application is archived, down to the trace of the form that was filled, so you know exactly what you sent where.

## Preferences

The matcher is driven by a single profile:

| Field | Example |
| --- | --- |
| **Work mode** | `remote`, `hybrid`, `onsite` — with a max commute or timezone band |
| **Roles** | `swe`, `backend`, `devops`, `platform`, `sre`, `data` |
| **Locations** | countries, cities, or timezone ranges for remote |
| **Seniority** | junior, mid, senior, staff |
| **Comp floor** | minimum salary, currency-aware |
| **Stack** | languages and tools you want to work in — and ones you refuse |
| **Dealbreakers** | visa sponsorship required, no on-call, no clearance, company blocklist |

## The resume agent

This is the part that already exists. Four skills in [`skills/`](skills/), which the apply stage runs in sequence per application:

| Skill | Role in the pipeline |
| --- | --- |
| [`resume-diagnoser`](skills/resume-diagnoser/SKILL.md) | Baseline ATS audit of your master resume — run once, fix what it finds. Scores parse-safety, keyword coverage, and impact separately. |
| [`resume-recruiter`](skills/resume-recruiter/SKILL.md) | Extracts the keywords a specific posting is really screening for, and which ones you're missing. Given a role instead of a posting, it samples 8–12 live listings and reports the market. |
| [`resume-rewriter`](skills/resume-rewriter/SKILL.md) | Rewrites your bullets against those keywords using the XYZ formula — "Accomplished X as measured by Y, by doing Z". |
| [`resume-hiring-manager`](skills/resume-hiring-manager/SKILL.md) | Mock interview for the roles that reply, grounded in your own bullets. Not automated — you run this yourself. |

They work standalone in Claude Code today. Point Claude at a posting and your resume:

```
/resume-recruiter
```

Each one finds your resume on its own — a path, a `*resume*` / `*cv*` file in the current directory, or pasted text, with PDF and `.docx` extracted automatically — and asks for whatever else it needs (target role, industry, seniority) one question at a time. Invoking bare is fine.

**State passes through a `resume-workspace/` folder** created wherever you run them: `profile.md` and `resume.md` are written by whichever skill runs first, then `diagnosis.md` → `keywords.md` → `bullets-rewritten.md` → `interview-log.md` as each stage feeds the next. So you answer the intake questions once, and the apply pipeline gets a defined handoff between stages rather than copy-paste. The folder is gitignored — it holds your actual resume.

**The agent never invents numbers.** Before rewriting, it lists every bullet lacking a metric and asks you for all of them in one batch. For anything you can't recall it offers a relative framing ("cut deploy time from hours to minutes"), a scope framing, or an explicit `[verify before sending]` placeholder. It only writes a numeric estimate if you ask, marked `[estimate, verify before sending]` — a fabricated metric on a resume is a fireable offense discovered later. Same rule on keywords: it won't suggest one your actual work can't support, so there's nothing to stuff.

## Applying beyond the APIs

Only a minority of jobs can be applied to over an API. The rest — Workday, iCIMS, every hand-rolled company career page — have a web form and nothing else. Restricting the tool to API-submittable postings throws away most of the deck, so there's a second path ([docs/14](docs/14-browser-agent.md)):

- **A real browser, driven by a sidecar**, filling the employer's own form as you, with your own sessions. Headed, so you can watch.
- **Deterministic first.** Checked-in recipes per ATS platform supply the selectors. The model is a fallback for unknown fields — and even then it only picks *which stored answer* goes where. It never composes a value.
- **An `AnswerBook`.** Notice period, work authorization, salary expectation, "how did you hear about us" — you answer each once, ever. EEO questions default to *decline to self-identify* and no model may ever touch them.
- **You press submit.** Every time. The sidecar refuses a submit action without a single-use token minted by a human, and it verifies the outcome against both a confirmation page and a confirmation email before it will claim the application was sent.
- **Accounts and codes handled.** Workday makes an account per employer; passwords are generated, stored in your OS keychain, and never shown to the model. Emailed verification codes are extracted by regex from a scoped mailbox read; SMS codes are pushed to your phone for *you* to read ([docs/15](docs/15-accounts-identity.md), [docs/16](docs/16-mailbox.md)).

What this explicitly is not: CAPTCHA solving, fingerprint spoofing, proxy rotation, or unattended sending. A site that blocks automation has succeeded, and that application becomes a link you open yourself.

## Roadmap

- [ ] **M1 — Aggregator.** One source end to end (Greenhouse), normalized schema, stored postings, dedup.
- [ ] **M2 — Preferences + matcher.** Profile schema, scoring, filtered deck.
- [ ] **M3 — Swipe UI.** Card deck, keyboard and touch, left-swipes recorded.
- [ ] **M4 — Tailoring.** Wire the skills into a per-application agent run, rendered and ATS-verified. Human reviews the output before send.
- [ ] **M5a — Accounts, mailbox, AnswerBook.** Credential vault, employer signups, verification codes, form answers stored once.
- [ ] **M5b — Submission.** API submit where it exists; browser form fill with a human-pressed submit where it doesn't; prefilled draft otherwise.
- [ ] **M6 — Tracking.** Application archive, status, follow-up reminders, replies matched from your inbox.
- [ ] **M7 — Learning.** Feed swipe history and reply rates back into matching.

## Job sources

Not all sources can be automated, and this matters more than it looks:

| Source | Ingest | Submit |
| --- | --- | --- |
| Greenhouse, Lever, Ashby, Workable | Public job board APIs | Documented application endpoints |
| Workday, iCIMS, SuccessFactors, Taleo | Public tenant boards | Browser form fill, one candidate account per employer, you press submit |
| Company career pages | Per-site scraping | Browser form fill, or a prefilled draft if the site says no |
| LinkedIn, Indeed | Official APIs are gated | **No.** Automating Easy Apply violates their terms and gets accounts banned |

Build order follows that table: the ATS platforms with real APIs first, because they're the cheapest and least breakable.

**On LinkedIn specifically**, since it's the obvious question: what's supported is your own data export, keyword work on your own profile, and drafting referral messages for you to send. What isn't, and won't be, is Easy Apply automation, logged-in scraping, or the agent sending anything from your account. Even the "Apply with LinkedIn" button on employer sites gets skipped — it uploads LinkedIn's copy of your resume instead of the one just tailored to that posting, which defeats the point. Details in [docs/15](docs/15-accounts-identity.md).

## Design decisions

- **Human in the loop through M6.** Auto-submitting a tailored resume you haven't read is how you send the wrong company's name to a recruiter. Two gates: one on the content, one on the filled form — a perfect resume can still be attached to a form that dropped the upload.
- **Quality over volume.** The goal is 20 strong tailored applications a week, not 500 spray-and-pray ones. Mass low-effort applying is exactly what ATS filters are tuned to catch. The browser path widens *which* jobs are reachable; the 5/hour cap is unchanged by it.
- **Respect the sources.** Rate-limit ingestion, honor `robots.txt`, and skip any platform whose terms forbid automated applications rather than working around them. A banned LinkedIn account costs more than the automation saves.
- **Reading postings and applying to jobs get different rules.** Ingestion is unauthenticated, public-endpoints-only, at bot scale. Submission is authenticated as you, in your own accounts, twenty times a week, with you clicking. Conflating the two either kills the product or builds a scraper — [docs/09](docs/09-compliance.md) draws the line explicitly.
- **The model never holds a secret.** Passwords live in the OS keychain and are resolved by the browser sidecar after the model's last turn. There is no prompt, tool result, or transcript in which one can appear.

## Contributing

Not yet — the schema is still moving. Open an issue if you want a source supported.

## License

MIT
