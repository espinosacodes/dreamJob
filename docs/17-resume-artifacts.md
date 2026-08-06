# 17 — Resume artifacts

**Status: specified.** M4. Expands [07](07-apply-pipeline.md) §4 into the full lifecycle, because the file the browser agent uploads ([14](14-browser-agent.md)) has to be correct in ways markdown does not capture.

The skills in [08](08-resume-skills.md) work in markdown. Employers take PDFs, and occasionally DOCX. Everything between those two facts lives here.

```
master.pdf ──extract──> master-resume.md ──skills──> bullets-rewritten.md
                                                          │
                                            assemble ─────┤
                                                          ▼
                                                     resume.json  (render IR)
                                                          │
                                            ┌─────────────┴─────────────┐
                                            ▼                           ▼
                                       resume.pdf                  resume.docx
                                            │                           │
                                            └──────── verify ───────────┘
                                                          │
                                                          ▼
                                                   uploaded, hashed, archived
```

## 1. Ingest

The user owns one master resume, in whatever format they already have.

| Input | Extraction | Notes |
| --- | --- | --- |
| PDF | `pdftotext -layout` | `-layout` matters: without it, two-column resumes interleave into nonsense |
| DOCX | `textutil -convert txt` (macOS), `pandoc` elsewhere | |
| Markdown / plain text | As-is | The happy path |
| LinkedIn data export | `Profile.csv` + `Positions.csv` → markdown ([15](15-accounts-identity.md)) | A starting point, not a resume |

Extraction runs once and writes `~/.dreamjob/master-resume.md`. Same file the skills call `resume.md` ([08](08-resume-skills.md)) — one extraction, shared by the matcher, the agent, and the renderer, per the [03](03-data-model.md) rule against two extractions of the same document.

**The extraction is shown to the user before anything is built on it.** If `pdftotext` mangled the master, every downstream artifact inherits the damage. This is also the first real ATS signal the user gets: a master resume that doesn't extract cleanly is a master resume that doesn't parse at the employer either, and it routes straight into `resume-diagnoser`.

## 2. The grammar

`bullets-rewritten.md` has to be machine-assemblable, so the markdown the skills write and the renderer reads is a **fixed subset**, not free-form:

```markdown
## Experience

### Senior Backend Engineer — Fathom Analytics
Remote · Mar 2023 – Present

- Cut p99 checkout latency from 1.8s to 240ms by replacing …
- Owned the payments ingestion pipeline processing …
```

- `##` — section. One of: Summary, Experience, Education, Skills, Projects, Certifications.
- `###` — role, as `Title — Company`, followed by one metadata line: `Location · Start – End`.
- `-` — bullet. One line, no nesting, no bold, no links inside.
- No tables, no images, no HTML, no footnotes.

A file that doesn't parse fails the render with the offending line number rather than being best-effort rendered. Silent degradation here means a resume section quietly missing from the PDF that got sent.

Parsing produces `resume.json`, the render IR — a `ResumeDoc` in `dreamjob-core` ([03](03-data-model.md)), with its JSON Schema in `contract/` ([18](18-api-contract.md)) so Go can read what the core wrote. Markdown stays the contract with the skills because it is what a human edits at the review gate; `ResumeDoc` exists so the renderers don't each re-parse prose.

## 3. Assembly

The rewriter only rewrites the experience section ([08](08-resume-skills.md)). Assembly merges its output back into the whole document:

1. Start from `master-resume.md` parsed to `ResumeDoc`.
2. Replace the Experience section with `bullets-rewritten.md`, **preserving order, titles, employers and dates from the master** — those come from the structured master, not from the rewritten text. A model cannot change an employment date by writing one.
3. Reorder the Skills section so keywords marked *absent* or *buried* in `keywords.md` that the user genuinely has appear in the first line, and drop nothing.
4. Leave Education, Certifications and Projects untouched unless the posting names something in them.
5. Re-check length. Over two pages, the assembler drops the oldest roles' bullets to one line each before dropping anything recent — and reports what it dropped rather than doing it silently.

**Invariant:** every employer, title and date in the output must be byte-identical to the master. Enforced by diffing the structured fields, not by trusting the prompt. This is the mechanical half of the honesty rules in [09](09-compliance.md) — the skills are the intent, this diff is the enforcement.

## 4. Render

**PDF is the default and the only format guaranteed to exist.** Rendered by `dreamjob-core render` (Rust, `printpdf`) — the render and its verification are one pure step, which is why they live together and why neither is in Go ([02](02-architecture.md)).

Constraints, all inherited from what ATS parsers actually survive:

- Single column. No tables, no text boxes, no headers or footers, no icons or graphics, no columns of any kind.
- Standard section headings, spelled the standard way.
- Embedded selectable text. Never an image of text.
- One common font (Helvetica/Arial or Times), regular and bold only.
- Dates in one consistent format throughout.
- Contact details in the body, never in a header/footer region — ATS parsers routinely discard those.
- Hyperlinks carry their URL as visible text too, because a stripped anchor leaves a dead word.

**DOCX** when the form's accepted-file list demands it (Taleo and older iCIMS instances still do):

1. `pandoc` if installed — deterministic, well-tested.
2. Otherwise, OOXML template substitution: a checked-in `.docx` skeleton whose `document.xml` is rewritten from `ResumeDoc` and re-zipped. No ecosystem has a DOCX writer worth depending on here, and a template plus `zip` is a smaller surface than one.
3. Otherwise, upload the PDF and record `formatDowngrade` on the application, visible at the review gate.

Never rendered: TXT-only submissions (the form will take a PDF), RTF, or "paste your resume as text" boxes — those get `ResumeDoc` flattened to plain text with the same grammar rules, which is a fourth renderer and is explicitly in scope.

**Filenames** are `Firstname-Lastname-Role.pdf` — e.g. `Ana-Rivera-Backend-Engineer.pdf`. Never the company name: it ends up visible to the recruiter, it advertises that this is one of forty, and a stale company name in a filename is the same wrong-send failure [01](01-product-spec.md) counts as a release blocker.

**Metadata** is set accurately — Title and Author are the user's name and the document title. Nothing is stripped to conceal how the file was made, and nothing is injected. No hidden text, no white-on-white keywords, no invisible layers ([09](09-compliance.md)).

## 5. Verification

Three gates. A render that fails any of them is not a candidate for submission.

| # | Check | Method | On failure |
| --- | --- | --- | --- |
| 1 | **Round-trip** | `pdftotext -layout` the render, normalize whitespace, diff against the flattened `ResumeDoc` | Fail the render. Unparseable by us is unparseable by them |
| 2 | **Keyword landing** | Every keyword `keywords.md` marks as must-land and the user can support must appear in the extracted text | Fail — the tailoring didn't survive rendering, which silently defeats the whole pipeline |
| 3 | **Structural** | The `resume-diagnoser` parse-safety checks run against the extracted text: sections found, dates parseable, contact block detected, no column interleaving | Fail with the diagnosis attached |

Check 3 is the reason `resume-diagnoser` is a permanent part of the system rather than a one-time onboarding step: the same audit that grades the user's master resume grades every artifact the system generates. If the tool that says "your resume won't parse" would fail our own output, the output does not go out.

This is also why rendering lives on the server and never in the Flutter app ([07](07-apply-pipeline.md)) — the verification chain needs `pdftotext`.

## 6. Identity and archival

Artifacts are **content-addressed and immutable**:

```
~/.dreamjob/artifacts/
  resume-8f3a91c2.pdf         # sha256[:8] of the bytes
  resume-8f3a91c2.json        # the ResumeDoc that produced it
  resume-8f3a91c2.md          # the assembled markdown
```

The application workspace holds hardlinks, not copies, so 40 applications sharing one render cost one file:

```
applications/<id>/
  resume.pdf -> artifacts/resume-8f3a91c2.pdf
```

Rules:

1. **Never regenerate in place.** A re-run of tailoring produces a new hash and a new file; `Application.artifacts.resumePdf` is repointed. The old file stays — it is the record of what was sent.
2. **The hash is recorded on the `Application` at submit time** and re-verified against the file that was uploaded. This is the check that catches the [15](15-accounts-identity.md) autofill trap, where a Greenhouse candidate profile quietly substitutes its stored resume for ours.
3. **The uploaded filename is read back out of the form** after upload ([14](14-browser-agent.md)) and must match. A form showing a different filename than the one we uploaded is a failed run, not a warning.
4. Artifacts are gitignored and never leave the machine except to the employer the user chose.

## 7. Where the skills fit

| Stage | Skill or code | Artifact |
| --- | --- | --- |
| Ingest + extract | code | `master-resume.md` |
| Baseline audit | `resume-diagnoser` | `diagnosis.md` — run once on the master |
| Keyword gap, per posting | `resume-recruiter` mode A | `keywords-<company>-<role>.md` |
| Bullet rewrite | `resume-rewriter` | `bullets-rewritten.md` |
| Assemble | code | `resume.json` |
| Render | code | `resume.pdf`, `resume.docx` |
| Verify | code + `resume-diagnoser` checks | pass/fail + diagnosis |
| Interview prep | `resume-hiring-manager` | `interview-log.md` — never automated |

[08](08-resume-skills.md) proposes promoting assembly + render into a `resume-formatter` skill. The argument for: a user without dreamJob installed could run the whole chain in Claude Code. The argument against, which currently wins: verification shells out to `pdftotext` and gates a submission, and a gate that blocks sending something to an employer belongs in code with tests around it, not in a prompt.

## Open questions

- Should the grammar in §2 be enforced by patching the skills' output templates, or by a tolerant parser that repairs common drift? Patching the skills makes them stricter for standalone users, who may not want that.
- Two-page overflow currently truncates old roles. Is dropping a whole old role cleaner than one-lining several?
- Is the "paste as text" renderer worth building before a real form demands it?
- Does the user ever want to see `resume.json`, or is markdown the only representation that should surface at the review gate?
- Content-addressed artifacts dedupe nicely but make "show me every version of my resume in order" a query rather than a directory listing. Is a per-application copy simpler enough to be worth the disk?
