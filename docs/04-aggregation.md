# 04 — Aggregation

**Status: specified.** M1 builds Greenhouse end to end; the rest follow the same adapter contract.

Goal: every posting the user could plausibly want, normalized into one shape, deduplicated, with the raw payload kept.

## Source tiers

| Tier | Sources | Ingest | Submit | Build order |
| --- | --- | --- | --- | --- |
| 1 | Greenhouse, Lever, Ashby, Workable | Public job-board APIs, JSON, documented | Documented application endpoints | M1, M5b |
| 2 | Workday, iCIMS, SuccessFactors, Taleo | Public tenant boards, per-platform | Browser form fill + candidate account ([14](14-browser-agent.md), [15](15-accounts-identity.md)) | M5b |
| 3 | Company career pages | Per-site scraping, HTML | Browser form fill, or a prefilled draft where the site forbids automation | M5b |
| 4 | LinkedIn, Indeed | **Not ingested.** APIs are gated | **Never.** Automating Easy Apply violates their terms | Never |

Tier 4 is a decision, not a backlog item. See [09](09-compliance.md).

Ingestion rules are identical across tiers 1–3 and unaffected by how an application is later submitted: unauthenticated, public endpoints, `robots.txt` honoured, rate-limited. The two regimes are kept apart deliberately ([09](09-compliance.md)) — an adapter never logs in to read.

## Adapter contract

Every source implements `SourceAdapter` ([02](02-architecture.md)). Requirements:

1. `fetch()` returns a `Stream<RawPosting>` so a board with 900 postings streams instead of buffering.
2. `fetch()` MUST honour `since` where the source supports it (Greenhouse's `updated_after`, Lever's `updated_at` filter) and fall back to a full listing plus local diff where it doesn't.
3. `normalize()` MUST be pure: `(raw, target, now) -> JobPosting`, no network, no ambient clock. This is what makes re-normalization cheap and testable.
4. `rateLimit` is enforced by the runner, not by the adapter. Adapters declare, the runner obeys.
5. An adapter MUST NOT authenticate as a user or use an endpoint the source's docs don't publish.

### Per-source notes

**Greenhouse** — `https://boards-api.greenhouse.io/v1/boards/<token>/jobs?content=true`. One request returns the whole board with descriptions. Board tokens are discoverable from a company's careers URL. Cheapest tier-1 source and the reason it's M1.

**Lever** — `https://api.lever.co/v0/postings/<company>?mode=json`. Includes `categories` (team, location, commitment) and `lists` (the requirement bullet groups), which map well onto `requirements[]`.

**Ashby** — public job-board GraphQL/JSON per org slug. Descriptions come as structured blocks; keep the block structure when extracting `requirements[]`.

**Workable** — public account endpoint per subdomain. Sparser comp data than the others.

**Career pages** — one config entry per site: URL, CSS selectors for the listing and detail pages (parsed with the `html` package), and a poll interval. Fails loudly and quarantines when selectors stop matching, rather than silently ingesting empty postings. Every scraped site MUST pass the `robots.txt` check in [09](09-compliance.md) before it is added.

## Normalization

Order matters — later steps read earlier ones.

### 1. Text extraction
HTML → plain text preserving list structure. Bullets become `requirements[]` entries with source wording intact; `resume-recruiter` ranks by the posting's own vocabulary, so paraphrasing here corrupts the pipeline downstream.

### 2. Work mode
Resolve in this order, first hit wins:
1. Explicit source field (`remote: true`, Lever `workplaceType`).
2. Title markers: `(Remote)`, `Hybrid`, `Onsite`.
3. Location string markers: `Remote - EMEA`, `Hybrid — Berlin`.
4. Description phrases, matched against a maintained phrase list (`work from anywhere`, `X days per week in office`).
5. `'unknown'`.

Never default to `remote`. A posting that says "Remote" in the title and "3 days in office" in the body is `hybrid` and MUST be flagged `work_mode_conflict` in `reasons` — this specific lie is one of the three problems in the README.

### 3. Location
Parse each raw location into city/region/country/timezone, keeping `raw` verbatim. Multi-location postings keep all entries. `Remote - US` yields `remote_scope.countries: ['US']`, not a city.

### 4. Seniority
From title first (`Senior`, `Sr.`, `Staff`, `II`, `III`, `Lead`, `Principal`, `Intern`, `Grad`), then from `min_years_experience` in the requirements, then `'unknown'`. Manager and IC ladders are distinguished — "Engineering Manager" is not `staff`.

### 5. Compensation
Structured field if present (`comp.source = 'posted'`). Otherwise regex a range out of the description and mark `comp.source = 'range_in_text'`. Normalize hourly and monthly to annual for comparison but keep the original period. Never invent a range from a title or market data.

### 6. Stack tags
Map surface forms to canonical tags via a maintained synonym table: `Postgres|PostgreSQL|psql → postgres`, `k8s|Kubernetes → kubernetes`, `GoLang|Go → go`. Match on word boundaries — "Go" inside "Google" is the standard false positive. The table is data, versioned with the normalizer.

### 7. Dealbreakers
Phrase-matched out of the description: sponsorship ("we are unable to sponsor"), clearance ("active TS/SCI"), on-call ("participate in an on-call rotation"), years floor. Anything not stated is `'unstated'`, never `false`.

### Versioning
`normalizer_version` increments on any change to steps 2–7. A bump schedules a re-normalization pass over stored raw payloads — no re-fetching, no extra load on the source.

## Deduplication

Same role, five boards, one card.

### Stage 1 — exact fingerprint
```
fingerprint = sha256(
  company.name_normalized + '|' +
  title_normalized + '|' +
  work_mode + '|' +
  primary_location_country
)
```
`title_normalized` strips seniority markers, req IDs, department suffixes, and punctuation: `Senior Backend Engineer (Payments) - R2481` → `backend engineer payments`.

### Stage 2 — fuzzy pass
Within one company, compare postings not already fingerprint-matched:
- title trigram similarity ≥ 0.85, **and**
- same work mode or one is `'unknown'`, **and**
- overlapping locations or both remote, **and**
- description shingle similarity ≥ 0.6

Matches merge. Below threshold they stay separate — two genuinely different backend roles at the same company is common and merging them loses a real opportunity.

### Merge rules
- The merged posting keeps the **earliest** `first_seen_at` and the **latest** `last_seen_at`.
- All `sources[]` entries are retained.
- Field conflicts resolve by source tier, then by recency. A posted comp range beats an inferred one regardless of recency.
- The apply URL used downstream is the one from the source with `canSubmit: true`, preferring API submission over a form.
- A merge is recorded so it can be inspected and undone. Bad merges hide jobs, and a hidden job is invisible by definition.

## Scheduling and freshness

| Source type | Default interval |
| --- | --- |
| Tier 1 board APIs | 6h |
| Career pages | 24h |
| A board that returned 0 postings twice in a row | back off to 48h, then alert |

- Runs are staggered so ingestion isn't one thundering burst.
- A posting not seen in two consecutive successful runs of its board gets `closed_at` set and drops out of the deck. Two runs, not one — a single flaky response MUST NOT close a board's worth of jobs.
- Ingestion failures are surfaced as deck staleness ("Greenhouse last synced 19h ago"), never as an empty deck.

## Quarantine

A posting that fails normalization is written to a quarantine table with the raw payload and the error, and the run continues. Quarantine is reviewed by the user, and a quarantined posting is re-processed automatically on the next `normalizer_version` bump. One malformed payload MUST NOT abort a board.

## Open questions

- Board discovery: how does a user find the Greenhouse token for a company they like? Manual list, a crawl of careers pages, or a curated seed list shipped with the repo?
- Is there a "company watchlist" concept distinct from source config — follow a company, resolve whichever ATS they use?
- Should closed postings be purged after N days, or kept forever as market data for M7?
