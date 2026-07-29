# dreamJob

A set of [Claude Code](https://claude.com/claude-code) skills for landing the job — resume diagnosis, keyword research, bullet rewriting, and mock interviews — plus a project rubric tracker.

Each skill is a folder containing a single `SKILL.md`. Claude Code loads the skill automatically when your request matches its `description`, or you can invoke it explicitly with a slash command.

## Skills

| Skill | What it does |
| --- | --- |
| [`resume-diagnoser`](resume-diagnoser/SKILL.md) | Audits a resume the way a real ATS would. Flags parsing killers, weak sections, and missing signals, then ranks the top 5 fixes by impact. |
| [`resume-recruiter`](resume-recruiter/SKILL.md) | Recruiter's-eye keyword research: the top 15 keywords in live job posts for your target role, which ones your resume is missing, trending skills, and buzzwords to cut. |
| [`resume-rewriter`](resume-rewriter/SKILL.md) | Rewrites every experience bullet using Google's XYZ formula — "Accomplished X as measured by Y, by doing Z" — with metrics and action verbs. |
| [`resume-hiring-manager`](resume-hiring-manager/SKILL.md) | Runs a mock interview as the hiring manager for your target role. Scores each answer out of 10 and ends with a hireability score and study plan. |
| [`circleguard-checklist`](circleguard-checklist/SKILL.md) | Reads and updates the IngeSoft V rubric checklist for the CircleGuard final project. |

### Suggested order

The resume skills chain naturally:

```
resume-diagnoser  →  resume-recruiter  →  resume-rewriter  →  resume-hiring-manager
   what's broken      what's missing       fix the bullets      rehearse the interview
```

`resume-rewriter` takes the missing-keywords list from `resume-recruiter` as input, so run them in that order for best results.

## Install

Clone into your personal skills directory so the skills are available in every project:

```bash
git clone git@github.com:espinosacodes/dreamJob.git
cp -R dreamJob/*/ ~/.claude/skills/
```

Or symlink an individual skill:

```bash
ln -s "$PWD/resume-diagnoser" ~/.claude/skills/resume-diagnoser
```

Project-scoped instead of global? Use `.claude/skills/` inside the project repo.

## Usage

Start Claude Code and either describe what you want or call the skill directly:

```
/resume-diagnoser
```

```
Why isn't my resume getting interviews? Target role: Senior Backend Engineer.
```

Every resume skill asks for the details it needs — target role, industry, seniority, and your resume text — one at a time before it starts, so you can invoke it with no arguments.

## Notes

- `circleguard-checklist` points at an absolute path (`~/Documents/swe5/circle-guard-public/docs/RUBRIC_CHECKLIST.md`). Adjust it if your checkout lives elsewhere.
- The resume skills never invent metrics. Where a number is estimated it is marked `[estimate, verify before sending]` — always verify before you send the resume out.

## License

MIT
