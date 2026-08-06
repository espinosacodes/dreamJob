# 13 — Practice tracks

**Status: process doc.** Three skills you want reps in — AI engineering, algorithms, SQL — and where each one lives.

dreamJob covers two of them naturally and the third only partly. The point of this doc is to be honest about which is which, so you don't convince yourself that shipping features is the same as practising fundamentals.

| Track | Covered by the project? | Where the reps come from |
| --- | --- | --- |
| **AI engineering** (LangGraph, multi-agent, model swapping, evals) | Yes, and it's the best fit | Rebuild the resume chain as a graph, run it on several models, measure which wins |
| **Algorithms** (DFS, complexity) | Partly — a handful of real instances | Project problems for depth, LeetCode for coverage |
| **SQL** | Partly — real queries, small data | Project queries for realism, drilling for range |

---

## Track 1 — AI engineering

### What you're rebuilding

The resume chain in [08](08-resume-skills.md) is already a multi-stage agent pipeline: **recruiter → rewriter → cover letter**, passing state through files. That is a LangGraph graph wearing a different coat. Rebuilding it as one gives you a real multi-agent system with a real task instead of a toy.

The graph, at minimum:

```
                    ┌──────────────┐
  posting ─────────►│  extract     │  keywords, requirements, dealbreakers
  resume  ─────────►│  (recruiter) │
                    └──────┬───────┘
                           ▼
                    ┌──────────────┐
                    │   rewrite    │  bullets in XYZ form
                    └──────┬───────┘
                           ▼
                    ┌──────────────┐
                    │   critique   │  fabrication check, keyword coverage
                    └──────┬───────┘
                     pass  │  fail → loop back to rewrite (bounded)
                           ▼
                    ┌──────────────┐
                    │ cover letter │
                    └──────────────┘
```

The critique→rewrite loop is where the interesting engineering is: a bounded retry with a real stopping condition, not a fixed chain. That's the thing worth being able to talk about.

### Where it plugs in

**The seam already exists.** [07](07-apply-pipeline.md) specs the tailoring agent as a subprocess or an HTTP call — the Dart backend doesn't care what's on the other end. So the LangGraph service is a **sidecar**: a small Python HTTP service on localhost, and the Dart pipeline POSTs to it instead of spawning `claude -p`.

```
dreamjob_server (Dart) ──HTTP──► tailor-service (Python, FastAPI + LangGraph)
                                          │
                                          ├──► Claude (Messages API)
                                          ├──► DeepSeek-R1 (hosted, or a distill locally)
                                          └──► Qwen (locally via Ollama)
```

**The cost, stated plainly:** this is a third language in a two-language project. It's worth it because LangGraph is Python-only and it's the tool you actually want on your resume — but keep the seam narrow (one endpoint, JSON in, JSON out) so the Dart side never learns anything about Python.

Keep the `claude -p` path working. Two backends behind one interface is what makes the comparison in the next section possible.

### Model swapping

Make the model a config value, not a code path. One `models.yaml`, one adapter interface, N implementations.

| Model | How to run it | Note |
| --- | --- | --- |
| Claude (`claude-opus-5`) | Messages API | Your quality baseline — the thing others have to beat |
| DeepSeek-R1 | Hosted API (DeepSeek, or an aggregator) | The full model is far too large for a laptop. Its **distills** (R1-Distill-Qwen 7B/14B/32B) run locally via Ollama and are the practical local reasoning option. |
| Qwen | Ollama, locally | 7B/14B fit comfortably on decent hardware; larger needs a GPU box |

Check current versions before pinning — the open-model landscape moves faster than any doc. What matters for practice is the *shape*: one interface, several providers, swappable by config.

**The interesting questions this setup lets you actually answer**, rather than guess at:

- Does a reasoning model (R1-style) beat a same-size instruct model on the *critique* node specifically? That node is judgment, not generation — the hypothesis is that it should, and you can prove or kill it.
- Can a small local model do extraction (recruiter) well enough that you only pay for the rewrite?
- Does a mixed graph — cheap local extraction, expensive rewrite, cheap critique — beat all-Claude on cost per acceptable output?

That last question is AI engineering. "Which model is best" is not.

### Evals — the part that matters

Without evals you're vibing, and vibing is the thing employers are tired of. Build the harness before the third model.

**Golden set.** 10–20 `(resume, posting)` pairs with known-good outcomes. Use your own resume plus real postings you've already read. Small and hand-curated beats large and noisy.

**Deterministic checks first** — cheap, fast, no LLM, and they catch the failures that actually matter:

| Check | Fails when | Why it's the important one |
| --- | --- | --- |
| **Fabrication** | A number appears in the output that isn't in the input resume, the posting, or `metrics.md` | This is the project's core honesty rule ([09](09-compliance.md)) turned into an assertion. A model that invents "improved performance by 40%" fails, full stop — no judge needed. |
| Placeholder leakage | `[verify before sending]` survives into a "finished" output | Blocks approval anyway; catch it here |
| Keyword coverage | Δ between posting keywords present before vs after | The measurable point of the whole pipeline |
| Format | Bullet starts with a weak verb, exceeds two lines, contains banned filler | Cheap, and models differ a lot here |

**LLM-as-judge second**, for what can't be asserted: XYZ-formula compliance, whether a bullet is defensible in an interview, tone. Use a strong model as judge, judge one dimension at a time, and — important — **spot-check the judge against your own ratings** on a few samples. An unvalidated judge is a random number generator with good manners.

**Pairwise beats scoring.** "Is A or B better for this posting" is far more reliable from an LLM judge than "rate A from 1–10". Run a small tournament across models.

**Track per run:** model, prompt version, each check's result, tokens, cost, latency. A results table with those columns is the artifact — it's what makes "I evaluated three models" a real claim instead of a resume line.

**Regression gate.** A prompt change that regresses the deterministic checks doesn't ship. That single rule is most of what separates AI engineering from prompt fiddling.

### What to be able to say afterwards

You should be able to answer, with a number: which model, at which node, at what cost, and how you know. If you can't, the track isn't finished no matter how much code exists.

---

## Track 2 — Algorithms

The project contains a few genuinely algorithmic problems. They're worth doing carefully, but there aren't enough of them — LeetCode covers the range.

**Real instances in dreamJob:**

| Problem | The algorithm |
| --- | --- |
| Dedup merging ([04](04-aggregation.md)) — postings A~B and B~C must land in one group | **Connected components.** DFS over a similarity graph, or union-find. This is a textbook problem hiding in a product feature; do it by hand before reaching for a library. |
| Deck assembly ([05](05-matching.md)) — filter, score, rank, tie-break, paginate | Sorting with a composite comparator; the complexity question is whether you re-score everything on every deck request |
| Phone cache ([02](02-architecture.md)) | Bounded cache with eviction — the LRU question, in the wild |
| Swipe log fold ([03](03-data-model.md)) | Reducing an append-only log to current state; think about doing it incrementally rather than from scratch each time |
| Stack-tag matching ([04](04-aggregation.md)) | Word-boundary matching over a synonym table — where "Go" inside "Google" is the false positive you have to design out |

**The separate drilling**, because the project won't produce these on its own:

- **O(1) / amortized** — hash maps, sets, prefix sums, two pointers, LRU cache. The skill is recognising when a linear scan can become a lookup.
- **DFS/BFS** — grids, trees, graphs, cycle detection, topological sort, backtracking. Connected components you'll have already met for real.
- Then the usual spread: binary search, sliding window, heaps, intervals, DP once the rest is solid.

Cadence beats volume: a small number of problems per week, done without hints, explained out loud afterwards, beats grinding fifty you half-remember. The out-loud part is the part that transfers to a live interview.

---

## Track 3 — SQL

The project gives you realistic queries on unrealistically small data. Both halves matter.

**Real in dreamJob:** the deck query (filter + rank + paginate), dedup lookups by fingerprint, the tracker's aggregate views (reply rate by company, applications per week), migrations as the schema moves, and — the interesting one — **whether the deck is computed on read or on write**, which is a question with a real tradeoff and no obvious answer.

Do these in raw SQL first, then port to drift. Writing it through an ORM first means you learn the ORM, not SQL.

**The separate drilling**, since your tables will hold hundreds of rows and interviewers ask about millions: joins (all four kinds, and when each is wrong), `GROUP BY` with `HAVING`, window functions (`ROW_NUMBER`, `RANK`, `LAG` — these come up constantly and are the most common gap), CTEs including recursive, and reading a query plan. `EXPLAIN QUERY PLAN` on your own deck query is the best first exercise you have, because you'll care about the answer.

---

## Tying it together

One week, roughly: project work most days, a couple of algorithm problems, one SQL session, and one AI-engineering session that produces a row in the eval table. The eval table is the thing to protect — it's the only artifact here that's hard to fake and easy to talk about.

Then run [`resume-hiring-manager`](../skills/resume-hiring-manager/SKILL.md) against the bullets you write about all of this. It will ask "by how much, measured how?" — and this time you'll have the numbers.
