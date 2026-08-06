# 05 — Matching

**Status: specified.** M2 builds filters + scoring; the learned component lands in M7. The matcher lives in `dreamjob-core` (Rust) and is invoked by the Go service as `dreamjob-core match` ([02](02-architecture.md)) — it runs server-side, and the app only ever sees `Match` results.

The matcher's job is to make the deck short enough to finish. It runs in two stages: **hard filters** (binary, unforgiving) then **scoring** (weighted, explainable).

## Design rules

1. **Deterministic.** Same posting + same profile version + same matcher version ⇒ same score. No model call in the hot path. A deck the user can't reproduce is a deck they can't trust or debug.
2. **Explainable.** Every score carries `reasons[]` in the user's language. "Shown because: Go + Kubernetes, remote EU, comp above your floor."
3. **Unknown is not a default.** A missing field is scored as unknown with an explicit penalty, never coerced to the favourable value.
4. **Conservative filters.** A hard filter removes a posting the user will never see. Only apply one where a false negative is genuinely acceptable.

## Stage 1 — hard filters

A posting failing any of these gets `passed_filters: false` and never enters the deck. Failures are recorded in `filter_failures[]` so the user can audit what was dropped and loosen the profile.

| Filter | Rule | Unknown handling |
| --- | --- | --- |
| Work mode | `posting.work_mode ∈ profile.work_modes` | `unknown` **passes**, penalized in scoring |
| Location | Remote: posting's `remote_scope` must intersect the profile's countries/timezone band. Onsite/hybrid: within `max_commute_minutes` of `base_location` | No parseable location passes with a penalty |
| Refused stack | Any tag in `profile.stack.refuse` present ⇒ drop | n/a |
| Comp floor | Posted range max < floor ⇒ drop | No range: drop only if `comp_floor_applies_to_unposted` |
| Seniority | `posting.seniority ∈ profile.seniority`, ±1 band tolerated | `unknown` passes, penalized |
| Visa | `profile.needs_visa_sponsorship` and posting says no sponsorship ⇒ drop | `'unstated'` passes |
| Clearance | `profile.no_clearance` and clearance required ⇒ drop | absent = not required |
| On-call | `profile.no_on_call` and on-call required ⇒ drop | `'unstated'` passes |
| Blocklist | `company.name_normalized ∈ company_blocklist` ⇒ drop | n/a |
| Years floor | `min_years_experience` more than 2 above the user's band ⇒ drop | absent passes |
| Already seen | Swiped (either direction) or already applied ⇒ drop | n/a |
| Closed | `closed_at` set ⇒ drop | n/a |

The ±1 seniority tolerance and the +2 years slack are deliberate. Postings inflate requirements; a filter that takes them literally deletes real matches.

## Stage 2 — scoring

Score is a weighted sum of seven components, each normalized to 0–100.

```rust
pub struct MatchWeights {
    pub role_fit: f64,       // default 0.25
    pub stack_fit: f64,      // default 0.25
    pub seniority_fit: f64,  // default 0.15
    pub location_fit: f64,   // default 0.10
    pub comp_fit: f64,       // default 0.15
    pub company_fit: f64,    // default 0.05
    pub learned: f64,        // default 0.05 (0 before M7)
}
```

Weights are overridable per profile. They sum to 1.0; the loader normalizes if they don't.

### role_fit
Similarity between `title_normalized` and `profile.roles`, plus responsibility-section evidence. An exact role match scores 100; an adjacent role (`backend` profile vs a `platform` posting) scores in the 60s via a hand-maintained adjacency table; an unrelated title scores near 0 and usually fails role sanity anyway.

### stack_fit
```
want_hits = |posting.stack ∩ profile.stack.want|
want_total = |profile.stack.want|
coverage = want_hits / min(want_total, 5)      // 5 wanted tags is full marks
prominence = bonus for want-tags appearing in the title or first 3 requirements
stack_fit = clamp(100 * (0.7 * coverage + 0.3 * prominence))
```
Tags in `profile.stack.ok` contribute nothing either way. Tags in `refuse` already filtered the posting out.

### seniority_fit
Exact band = 100. One band up = 70 (a stretch role is often worth applying to). One band down = 40 (usually a comp and scope regression). `unknown` = 50.

### location_fit
Remote and in-band = 100. Remote with a timezone overlap under 4 hours = 60. Hybrid within commute = 80, scaled down linearly toward `max_commute_minutes`. Onsite within commute = 70. Unknown location = 40.

### comp_fit
Posted range entirely above the floor = 100, scaling down to 0 at the floor. No posted range = 50 with a `comp_unposted` reason string — neutral, because most postings still omit it and penalizing them hides half the market.

### company_fit
Size/stage preferences where data exists, blocklist adjacency, and repeat-employer signal (the user has right-swiped this company before). Absent data = 50. This is the weakest component and its 0.05 weight reflects that.

### learned
Zero until M7. See below.

### Composition
```
score = Σ (component × weight)
```
Plus two adjustments applied after the sum:
- **Freshness.** Postings older than 30 days lose up to 10 points, linearly to 60 days. Old postings are often already filled.
- **Conflict flag.** A `work_mode_conflict` from normalization ([04](04-aggregation.md)) caps the score at 70 and adds a visible warning to the card. The user should see it and judge, not have it silently dropped or silently trusted.

## Threshold and deck assembly

- Default deck threshold: **score ≥ 60**.
- The deck is sorted by score descending, then by `first_seen_at` descending.
- Ties break toward the newer posting.
- A card that scores ≥ 85 is marked a **strong match** in the UI.

If a day's deck has fewer than 5 cards, the UI offers to show the 60–45 band as a labelled "stretch" section rather than silently lowering the bar. If it has more than 40, the UI says so and offers to raise the threshold — the deck must stay finishable ([01](01-product-spec.md), U4).

## Explanations

`Match.reasons[]` is generated from whichever components dominated the score, plus any warnings. Format is short user-language phrases, not diagnostics:

```
["Go and Kubernetes, both on your want list",
 "Remote, EU timezones — inside your band",
 "€95–120k posted, above your floor",
 "⚠ title says Remote, description says 3 days in office"]
```

Every card shows its top three reasons. Every card can show all of them plus the raw component scores, because a user who can't interrogate the matcher will stop believing it.

## Learning (M7)

The learned component turns swipe history into a preference signal — without becoming an unauditable black box.

**Signals**
- Left-swipes with short dwell (< 2s): strong negatives, usually one visible attribute.
- Left-swipes with long dwell (> 8s): weak negatives — genuinely considered.
- Right-swipes: positives.
- Downstream outcomes: an application that got a response is a stronger positive than one that didn't; an abandonment at the review gate is a negative on a card the matcher had scored highly.

**Model.** Logistic regression over the same features the components use — stack tags, company, seniority delta, work mode, comp band, title tokens. Not a neural net, not an LLM. The reason is auditability: the user can be shown "you keep rejecting Java roles" as a coefficient, and can veto it.

**Guardrails**
1. `learned` weight is capped at 0.20 even if the user raises it. The explicit profile stays dominant.
2. No learned signal is applied until ≥ 100 swipes exist.
3. Learned adjustments MUST appear in `reasons[]` ("de-ranked: you've skipped 9 of 9 Java roles").
4. The user can reset the learned model without touching their profile.
5. Feedback loops are monitored: if the learned component drives a stack tag's exposure to zero, exploration re-injects a small number of such cards so the model can be corrected by evidence.

## Testing

The matcher is a pure function, so it is tested as one — and being in Rust with no I/O, it is testable to a standard the rest of the system can't reach:
- A fixture corpus of ~200 real postings, hand-labelled by the user as would-apply / would-skip.
- Precision and recall against those labels on every matcher change.
- Golden-file tests on `reasons[]` — an explanation regression is a product regression.
- **Property tests** (`proptest`): the score is monotonic in each component, always lands in 0–100, is unchanged by reordering `stack`, and never emits an empty `reasons[]` for a passing posting.
- `matcher_version` bumps on any weight or formula change, invalidating stored `Match` rows.

`computed_at` is an input, not `Utc::now()`. The freshness adjustment needs a clock, and the core is not allowed one ([02](02-architecture.md) invariant 10) — Go passes the time in, which is also what makes the freshness rule testable.

## Open questions

- Should hard-filtered postings be viewable somewhere ("42 dropped today: 30 onsite, 8 below floor")? Useful for tuning, and a possible anxiety source.
- Is title-similarity enough for `role_fit`, or does it need embeddings? Embeddings would break the no-model-in-the-hot-path rule unless precomputed at ingest.
- How should the matcher treat a company the user has already applied to this quarter — boost, penalize, or ignore?
