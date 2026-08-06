# 08 — Resume skills

**Status: built.** This is the only part of dreamJob that exists as working software today. It documents the four skills in [`skills/`](../skills/) as they are, and the contract the apply pipeline depends on.

## The chain

```
diagnoser ──> recruiter ──> rewriter ──> hiring-manager
   ↑              ↑             ↑              ↑
 once, on      per posting   per posting   before the
 the master    (or market)   (or master)   real interview
```

| Skill | Purpose | Runs |
| --- | --- | --- |
| [`resume-diagnoser`](../skills/resume-diagnoser/SKILL.md) | ATS audit of the master resume: parse-safety, weak sections, missing signals, top 5 ranked fixes | Once, then when the master resume changes |
| [`resume-recruiter`](../skills/resume-recruiter/SKILL.md) | Keyword gap list — targeted at one posting (mode A) or sampled across 8–12 live listings (mode B) | Per application (mode A) |
| [`resume-rewriter`](../skills/resume-rewriter/SKILL.md) | Rewrites experience bullets in XYZ form against the gap list | Per application |
| [`resume-hiring-manager`](../skills/resume-hiring-manager/SKILL.md) | 8-question mock interview against the bullets the user will actually send, with a scored debrief | Manual, before an interview |

Each is usable standalone in Claude Code — invoke bare and it finds the resume, asks only for what's missing, one question per message.

## Shared state contract

The four skills communicate through files in `./resume-workspace/`, created wherever they run. This is what makes them composable rather than four separate conversations.

| File | Written by | Read by | Contents |
| --- | --- | --- | --- |
| `profile.md` | whichever runs first | all four | `target_role`, `industry`, `seniority`, `resume_source`, `date` |
| `resume.md` | whichever runs first | all four | extracted plain text of the master resume |
| `diagnosis.md` | diagnoser | rewriter | full diagnosis, scores, ranked fixes |
| `keywords.md` | recruiter (mode B) | rewriter | top-15 keyword table + present/buried/absent verdicts |
| `keywords-<company>-<role>.md` | recruiter (mode A) | rewriter | same, scoped to one posting so per-application runs don't collide |
| `bullets-rewritten.md` | rewriter | hiring-manager | rewritten experience section, original order/titles/dates preserved |
| `interview-log.md` | hiring-manager | — | full Q&A plus debrief |

**Invariants**

1. **Read before asking.** A skill that finds `profile.md` never re-asks what it answers. The user does intake once.
2. **Never touch the original.** All output lands in `resume-workspace/`; the user copies across. The source resume file is read-only to every skill.
3. **The workspace is private.** `resume-workspace/` is gitignored — it holds the user's actual resume.
4. **Mode A namespacing.** Per-posting keyword files carry company and role in the filename so 20 applications don't overwrite each other.
5. **Degrade, don't stall.** Missing an upstream file, a skill says what it's missing, offers to run the upstream skill, and can proceed with a stated caveat. Only a missing resume is genuinely blocking.

## Honesty rules

These are enforced inside the skills and are the reason the pipeline can be trusted with a real job search.

- **No invented metrics.** The rewriter lists every bullet lacking a number and asks for all of them in one batched message. Unrecalled numbers get, in order: a relative framing ("cut deploy time from hours to minutes"), a scope framing ("across a 12-service platform"), or an explicit `[X% — verify before sending]` placeholder. A numeric estimate is written only on explicit request and is marked `[estimate, verify before sending]`.
- **No unearnable keywords.** The recruiter only lists keywords found in postings it actually read, and marks anything the user's real work can't support as a *learning target*, not a resume edit. No stuffing, no hidden text, no white-on-white.
- **No fabricated anything.** Employers, dates, titles, technologies — ask or placeholder.
- **Defensibility test.** If a rewrite would leave the user unable to answer "walk me through how you did that", it is too strong and gets pulled back. `resume-hiring-manager` exists partly to test exactly this.
- **Sampling honesty.** With no web access, the recruiter labels its output **pattern-based, not sampled** rather than passing recalled knowledge off as live research.

The `[verify before sending]` placeholder is load-bearing for the whole product: it is the mechanism by which "the agent doesn't know this number" survives all the way to the review gate, where it blocks approval ([07](07-apply-pipeline.md)).

## How the pipeline uses them

The apply pipeline treats `applications/<id>/` as the `resume-workspace/`, prepopulates `profile.md`, `resume.md`, `diagnosis.md`, and `posting.md`, then runs recruiter (mode A) → rewriter non-interactively. Full sequence in [07](07-apply-pipeline.md).

Mechanically this is a `claude -p` subprocess spawned by the Dart backend with that directory as its working directory — so the skills run exactly as they do when a human invokes them, reading and writing the same files. **The file-based contract is what makes automation cheap here**: no skill has to be rewritten to be scriptable.

Two behaviours change under automation:

1. **No interactive intake.** Everything the skills would ask for is prepopulated. A skill that still needs to ask halts the application at `needs_attention` rather than guessing — a guessed seniority produces a wrong resume.
2. **Batched metric questions have no one to answer them.** Known numbers come from a shared `metrics.md`; unknowns stay placeholders and block approval. The user answers each metric question once, ever — not once per application.

`resume-hiring-manager` is never automated. It is a conversation with the user, by design.

## Extending the chain

New skills join by following the same contract: read `profile.md` and `resume.md`, write one named artifact, declare who consumes it. Candidates worth considering:

- **`resume-formatter`** — render the rewritten markdown to an ATS-safe PDF with the verification chain from [17](17-resume-artifacts.md). Currently pipeline code; [17](17-resume-artifacts.md) §7 argues it should stay there, because it gates a submission and a gate belongs in tested code rather than a prompt.
- **`cover-letter-writer`** — stage 3 of the pipeline, currently inline.
- **`linkedin-profile`** — same keyword research, applied to a profile rather than a resume. Note this is *writing your own profile*, not automating the platform; it is the supported half of the LinkedIn story in [15](15-accounts-identity.md).

The pipeline's other model-driven stage, form-field mapping ([14](14-browser-agent.md)), is deliberately **not** a skill. It returns `AnswerBook` keys rather than prose, its output is consumed by a browser rather than a human, and it has no useful standalone mode — the contract that makes the four resume skills composable buys nothing there.

## Open questions

- Should the diagnoser re-run automatically when `resume.md` changes, or stay a deliberate step?
- Does mode B (market survey) belong in the automated pipeline at all, or is it purely a human-facing research tool?
- `metrics.md` is proposed in [07](07-apply-pipeline.md) but not implemented in the skills. Adding it means the rewriter reads a fourth upstream file — worth the contract growth?
