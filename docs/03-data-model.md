# 03 — Data model

**Status: specified.** Types are shown in **Rust**, because `dreamjob-core` is where the domain rules live and Rust's type system is the only one of the three that can enforce them ([02](02-architecture.md)).

They are a *reference projection*, not the source of truth. The wire contract is the OpenAPI document and JSON Schemas in `contract/` ([18](18-api-contract.md)); the Rust structs here, the Go structs in `dreamjob-server`, and the Dart classes in the app are all generated from it. **Hand-transcribing any of them is a defect.**

Derives are elided below; the real definitions carry `#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]` and `#[serde(rename_all = "snake_case")]`.

### Why Rust holds the reference shape

Two rules in this doc are load-bearing and neither survives a careless port:

1. **`Unknown` is a value, not an absence.** Rust makes it a variant that every `match` must handle. Go will happily let a `switch` fall through it.
2. **`None` means "the posting did not say" and MUST NOT become `false`.** `Option<bool>` says this; Go's `bool` zero value says the opposite by default. Every tri-state field crosses into Go as `*bool` or an explicit option type, and a plain `bool` on one of these fields is a review-blocking bug.

Go and Dart projections are mechanically derived, but those two properties are the ones to check by hand.

Entities: `JobPosting`, `Profile`, `Match`, `SwipeEvent`, `Application`, plus the account/browser/mailbox/artifact types added by [14](14-browser-agent.md)–[17](17-resume-artifacts.md).

## Shared enums

```rust
pub enum SourceId { Greenhouse, Lever, Ashby, Workable, CareersPage }

pub enum WorkMode { Remote, Hybrid, Onsite, Unknown }

pub enum Seniority { Intern, Junior, Mid, Senior, Staff, Principal, Unknown }

pub enum EmploymentType { FullTime, PartTime, Contract, Internship, Unknown }
```

These are `#[non_exhaustive]`-adjacent in spirit but deliberately are not: adding a variant SHOULD break every `match` in the core, because a new work mode that silently falls into a catch-all arm is exactly the failure this design is avoiding.

`unknown` is a first-class value everywhere. Postings routinely omit work mode and seniority, and a matcher that guesses silently is a matcher that lies. Unknowns are scored explicitly ([05](05-matching.md)), never coerced to a default.

## JobPosting

One row per real-world job, not per source listing. Cross-posts collapse into `sources`.

```rust
pub struct JobPosting {
    pub id: Ulid,                        // ours, stable across re-ingests
    pub fingerprint: String,             // dedup key — see 04
    pub sources: Vec<PostingSource>,     // invariant: never empty; see rules

    pub title: String,
    pub title_normalized: String,        // lowercased, seniority and noise stripped
    pub company: Company,

    pub work_mode: WorkMode,
    pub locations: Vec<Location>,        // as posted; may be several
    pub remote_scope: Option<RemoteScope>,

    pub seniority: Seniority,
    pub employment_type: EmploymentType,
    pub comp: Option<Compensation>,
    pub stack: Vec<String>,              // normalized tags: "go", "kubernetes"

    pub description_text: String,        // what the matcher and the agent read
    pub description_html: Option<String>,// preserved for the UI
    pub requirements: Vec<String>,       // extracted bullets, source wording kept
    pub dealbreakers: Dealbreakers,

    pub posted_at: Option<DateTime<Utc>>,// as claimed by the source
    pub first_seen_at: DateTime<Utc>,
    pub last_seen_at: DateTime<Utc>,
    pub closed_at: Option<DateTime<Utc>>,// set when it disappears from its board

    pub normalizer_version: u32,
}

pub struct PostingSource {
    pub source: SourceId,
    pub source_job_id: String,
    pub board: String,                   // greenhouse token, lever slug, hostname…
    pub url: String,                     // canonical posting page
    pub apply_url: String,
    pub raw: serde_json::Value,          // untouched source payload — never rewritten
    pub fetched_at: DateTime<Utc>,
}

pub struct Company {
    pub name: String,
    pub name_normalized: String,
    pub domain: Option<String>,
    pub logo_url: Option<String>,
}

pub struct Location {
    pub raw: String,                     // as posted: "Remote - EMEA", "NYC (Hybrid)"
    pub city: Option<String>,
    pub region: Option<String>,
    pub country: Option<CountryCode>,    // ISO 3166-1 alpha-2
    pub timezone: Option<String>,        // IANA
}

pub struct RemoteScope {
    pub anywhere: bool,
    pub countries: Vec<CountryCode>,
    pub timezone_range: Option<(i8, i8)>, // UTC offsets, inclusive
}

pub enum CompPeriod { Year, Month, Hour }
pub enum CompSource { Posted, RangeInText, Absent }

pub struct Compensation {
    pub min: Option<Decimal>,
    pub max: Option<Decimal>,
    pub currency: CurrencyCode,          // ISO 4217
    pub period: CompPeriod,
    pub equity_mentioned: bool,
    pub source: CompSource,
}

/// `None` means the posting did not say. Never coerce that to `false`.
pub struct Dealbreakers {
    pub visa_sponsorship: Option<bool>,
    pub security_clearance: Option<bool>,
    pub on_call: Option<bool>,
    pub min_years_experience: Option<u8>,
    pub citizenship_required: Option<Vec<CountryCode>>,
}
```

`Decimal` rather than `f64` for money, and `CountryCode`/`CurrencyCode` as newtypes rather than `String`: comp comparison against a floor is a correctness path, and a currency mismatch that type-checks is a silent wrong answer.

**Rules**

- `sources` MUST be non-empty. Rust cannot express that in `Vec`, so it is a constructor invariant with a test, and the JSON Schema carries `minItems: 1` so the contract enforces it for Go and Dart too.
- `raw` MUST be stored verbatim per source. Re-normalizing without re-fetching depends on it.
- `descriptionText` MUST be the text the matcher and the agent both read. Two different extractions of the same posting is a class of bug worth designing out.
- `CompSource` distinguishes a posted range from one scraped out of prose. Never present an inferred range as posted.
- Deleting a posting is not a thing. One that vanishes from its board gets `closedAt` and stays.

## Profile

The single file that drives matching. Human-editable — a document the user owns, not app state. Stored as `profile.yaml` on the server and loaded into this shape; the app edits it through the API.

```rust
pub struct Profile {
    pub version: u32,                    // bumped on every edit; Match rows reference it

    pub roles: Vec<String>,              // "backend", "platform", "sre", "data"
    pub seniority: Vec<Seniority>,       // acceptable band

    pub work_modes: Vec<WorkMode>,
    pub max_commute_minutes: Option<u16>,// hybrid/onsite only
    pub base_location: Option<Location>,
    pub remote: RemotePreference,

    pub comp_floor: Option<CompFloor>,
    pub comp_floor_applies_to_unposted: bool,

    pub stack: StackPreference,
    pub dealbreakers: ProfileDealbreakers,

    pub resume_path: PathBuf,            // master resume, the tailoring baseline
    pub weights: Option<MatchWeights>,   // override of the defaults in 05
}

pub struct RemotePreference {
    pub countries: Vec<CountryCode>,
    pub timezone_range: Option<(i8, i8)>,
}

pub struct CompFloor {
    pub amount: Decimal,
    pub currency: CurrencyCode,
    pub period: CompPeriod,
}

pub struct StackPreference {
    pub want: Vec<String>,               // scored positively
    pub ok: Vec<String>,                 // neutral
    pub refuse: Vec<String>,             // hard filter
}

pub struct ProfileDealbreakers {
    pub needs_visa_sponsorship: bool,
    pub no_on_call: bool,
    pub no_clearance: bool,
    pub company_blocklist: Vec<String>,  // normalized company names
    pub min_company_size: Option<u32>,
    pub max_company_size: Option<u32>,
}
```

Note the asymmetry with `Dealbreakers`: the *posting's* flags are `Option<bool>` because a posting may be silent, while the *profile's* are plain `bool` because the user always has a position, even if it is "don't care" expressed as `false`. Getting this backwards in either direction is a filter bug.

A profile edit bumps `version`, which invalidates existing `Match` rows rather than mutating them.

## Match

The matcher's verdict on one posting under one profile version.

```rust
pub struct Match {
    pub posting_id: Ulid,
    pub profile_version: u32,
    pub matcher_version: u32,

    pub score: f64,                      // 0–100
    pub passed_filters: bool,            // false => hard-filtered, never shown
    pub filter_failures: Vec<FilterId>,  // e.g. [WorkMode, CompFloor]

    pub components: MatchComponents,
    pub reasons: Vec<String>,            // human-readable, shown on the card
    pub computed_at: DateTime<Utc>,      // passed in; the core has no clock
}

pub struct MatchComponents {
    pub role_fit: f64,
    pub stack_fit: f64,
    pub seniority_fit: f64,
    pub location_fit: f64,
    pub comp_fit: f64,
    pub company_fit: f64,
    pub learned: f64,                    // from swipe history; 0 until M7
}
```

`filter_failures` is an enum, not a string: it is rendered in the UI and queried in analytics, and a typo'd `"compfloor"` should not compile.

`reasons` is a product feature, not a debug field. A card that can't say why it's in the deck erodes trust in the deck.

## SwipeEvent

Append-only. Training data for M7 and the audit trail for "why did I apply here".

```rust
pub enum SwipeDirection { Right, Left, Save }

pub struct SwipeEvent {
    pub id: Uuid,                        // client-generated; offline replay is idempotent
    pub posting_id: Ulid,
    pub direction: SwipeDirection,
    pub at: DateTime<Utc>,
    pub dwell_ms: u32,                   // card shown → swiped; a deliberation proxy
    pub card_version: u32,               // which card layout they saw
    pub match_score: f64,                // score at swipe time, denormalized on purpose
    pub profile_version: u32,
    pub reason: Option<String>,          // optional: "too junior", "bad stack"
    pub compensates: Option<Uuid>,       // id of the event this undoes
}
```

Undo appends an event with `compensates` set. Nothing is deleted; the deck's current state is a fold over the log. Because the app can swipe offline, `id` is minted client-side — the server treats a re-sent id as a no-op.

## Application

One per right-swipe that entered the pipeline.

```rust
pub enum ApplicationStatus {
    Queued,
    Tailoring,
    AwaitingReview,
    Approved,
    Submitting,
    AwaitingVerification,  // parked on an email/SMS challenge — see 15, 16
    Submitted,
    SubmitUnverified,      // form sent, neither confirmation signal landed — see 14
    AwaitingManualSubmit,
    SubmitFailed,
    NeedsAttention,
    Abandoned,
    Responded,
    Rejected,
    Interviewing,
    Closed,
}

pub struct Application {
    pub id: Ulid,
    pub posting_id: Ulid,
    pub swipe_event_id: Uuid,
    pub status: ApplicationStatus,

    pub workspace_path: PathBuf,         // applications/<id>/
    pub artifacts: ApplicationArtifacts,

    pub agent_runs: Vec<AgentRun>,
    pub approved_at: Option<DateTime<Utc>>,
    pub approved_by: ApprovedBy,         // one variant only, through M6
    pub submitted_at: Option<DateTime<Utc>>,
    pub submit_method: Option<SubmitMethod>,

    pub outcome: Option<Outcome>,
    pub follow_up_at: Option<DateTime<Utc>>,
}

/// Deliberately an enum with one variant rather than a String. Adding a second
/// is a design decision that has to be written down, not a value someone passes.
pub enum ApprovedBy { Human }

pub struct ApplicationArtifacts {
    pub keywords_md: Option<PathBuf>,    // resume-recruiter output for this posting
    pub bullets_md: Option<PathBuf>,     // resume-rewriter output
    pub resume_pdf: Option<PathBuf>,     // rendered — the file actually sent
    pub resume_sha256: Option<Sha256>,   // re-verified at upload — see 17
    pub resume_docx: Option<PathBuf>,    // only when the form demands it
    pub cover_letter_md: Option<PathBuf>,
    pub submission_receipt: Option<PathBuf>,
    pub browser_run_id: Option<Ulid>,    // set when submit_method == Browser
}

pub enum SubmitMethod { Api, Browser, Manual }

pub enum OutcomeKind { NoResponse, Rejected, Screen, Interview, Offer }

pub struct Outcome {
    pub first_response_at: Option<DateTime<Utc>>,
    pub kind: OutcomeKind,
    pub notes: Option<String>,
}

pub enum AgentStage { Recruiter, Rewriter, CoverLetter, FormMapping }

pub struct AgentRun {
    pub stage: AgentStage,
    pub started_at: DateTime<Utc>,
    pub ended_at: Option<DateTime<Utc>>,
    pub ok: bool,
    pub error: Option<String>,
    pub transcript_path: Option<PathBuf>,
}
```

**The status machine is the best type-system exercise in the project.** [12](12-build-guide.md) asks whether an illegal transition can be made to fail at compile time. In Rust the honest answer is a typestate (`Application<Queued>` → `Application<Tailoring>`) which is elegant and fights the database, or a single `fn transition(self, ev: Event) -> Result<Self, IllegalTransition>` with an exhaustive `match` — one function, one table, one place to test. Prefer the second and know why you rejected the first.

**Rules**

- `approvedAt` is required before `submitting`. Enforced in the submitter, not the UI.
- `artifacts.resumePdf` is the exact file sent. It is never regenerated in place — a follow-up tailoring run writes a new file.
- Status transitions are one-way except `queued ⇄ tailoring` (retry), `submitting ⇄ awaitingVerification` (a challenge parks and resumes the run), and the terminal outcome states.

## SiteAccount and CredentialRef

Accounts dreamJob holds at employer systems ([15](15-accounts-identity.md)). The secret is not in this model — that is the point of it.

```rust
pub enum SiteAccountKind { AtsTenant, AtsGlobal, CareerPage }
pub enum EmailStrategy { PlusTag, Plain, CatchAll }

pub struct SiteAccount {
    pub id: Ulid,
    pub domain: String,                  // e.g. acme.wd1.myworkdayjobs.com
    pub kind: SiteAccountKind,
    pub platform: String,                // "workday", "greenhouse", "icims", "custom"

    pub email: String,                   // the alias used to register
    pub email_strategy: EmailStrategy,
    pub credential_ref_id: CredentialRefId, // keychain handle — never a secret
    pub browser_profile_path: PathBuf,   // persistent user-data-dir

    pub created_at: DateTime<Utc>,
    pub last_login_at: Option<DateTime<Utc>>,
    pub phone_verified: bool,
    pub application_count: u32,
}

/// A newtype, so a keychain handle can never be passed where a password is
/// expected — and so `impl Debug` can be written by hand to print `<ref>`.
pub struct CredentialRefId(String);

pub struct CredentialRef {
    pub id: CredentialRefId,
    pub service: &'static str,           // always "dreamjob"
    pub username: String,
    pub created_at: DateTime<Utc>,
    pub rotated_at: Option<DateTime<Utc>>,
}
```

**Rules**

- A `CredentialRef` MUST NOT have a `secret` field, in this model or in the database schema. The keychain is the only store.
- No secret, session cookie, or browser profile ever appears in an API response the phone can read.
- `browserProfilePath` contents are credential-grade: cookies there authenticate as the user.

## BrowserRun

One per browser-driven submission or registration attempt ([14](14-browser-agent.md)).

```rust
pub enum BrowserRunKind { Register, Login, DryRun, Submit }
pub enum BrowserRunOutcome { Succeeded, Halted, Failed, Blocked }
pub enum FillTier { Recipe, SemanticMap, Human }

pub struct BrowserRun {
    pub id: Ulid,
    pub application_id: Option<Ulid>,    // None for a bare register/login run
    pub site_account_id: Ulid,
    pub kind: BrowserRunKind,

    pub recipe_id: String,
    pub recipe_version: u32,
    pub highest_tier_used: FillTier,     // recipe-only runs are the trustworthy ones

    pub fields: Vec<FilledField>,
    pub outcome: BrowserRunOutcome,
    pub halt_reason: Option<String>,     // quoted question, CAPTCHA, mismatch…
    pub trace_path: PathBuf,             // trace.zip + screenshots
    pub confirmation_path: Option<PathBuf>,

    pub started_at: DateTime<Utc>,
    pub ended_at: Option<DateTime<Utc>>,
    pub confirmed_by: Option<ApprovedBy>,// the submit-gate token holder
}

pub struct FilledField {
    pub selector_or_ref: String,
    pub answer_key: Option<AnswerKey>,   // None for uploads
    pub rendered_value_hash: Sha256,     // never the value, for anything sensitive
    pub read_back_value: String,         // what the DOM held afterwards
    pub verified: bool,                  // rendered == read_back
    pub tier: FillTier,
}
```

**Rules**

- `outcome == succeeded` requires `confirmedBy == 'human'` on a `submit` run. Enforced in the submitter.
- A run with any `verified == false` field MUST NOT reach the submit gate.
- Password fields are recorded as `FilledField` with `renderedValueHash` only, and are scrubbed from the trace.

## VerificationChallenge

```rust
pub enum ChallengeKind { EmailCode, EmailLink, Sms }
pub enum ChallengeOutcome { Resolved, Expired, Refused, Cancelled }

pub struct VerificationChallenge {
    pub id: Ulid,
    pub browser_run_id: Ulid,
    pub domain: String,                  // who asked — shown before the user answers
    pub kind: ChallengeKind,
    pub opened_at: DateTime<Utc>,
    pub expires_at: DateTime<Utc>,       // opened_at + 5 min
    pub outcome: Option<ChallengeOutcome>,
}
```

**The code itself is never a field.** Not stored, not logged, not in a transcript ([16](16-mailbox.md)). At most one challenge is open system-wide.

## MailMessage

```rust
pub struct MailMessage {
    pub id: String,                      // provider message id
    pub application_id: Option<Ulid>,    // None until attributed
    pub confidence: AttributionConfidence,

    pub from_domain: String,
    pub delivered_to_alias: Option<String>, // the plus-tag, when present
    pub subject: String,
    pub body_text: String,
    pub received_at: DateTime<Utc>,

    pub classified: Option<OutcomeKind>,
    pub classification_confirmed_by_user: bool,
}

pub enum AttributionConfidence { Exact, Strong, Weak }
```

**Rules**

- A message with `confidence == weak` MUST NOT write an `Outcome`; it is a suggestion until the user taps it.
- Messages matching no application are counted and discarded, never retained.
- Attachments are never downloaded.

## ResumeArtifact

Content-addressed renders ([17](17-resume-artifacts.md)).

```rust
pub struct ResumeArtifact {
    pub sha256: Sha256,                  // identity — the filename is sha256[..8]
    pub pdf_path: PathBuf,
    pub docx_path: Option<PathBuf>,
    pub json_path: PathBuf,              // the ResumeDoc that produced it
    pub markdown_path: PathBuf,
    pub rendered_at: DateTime<Utc>,
    pub round_trip_verified: bool,
    pub keywords_landed: bool,
    pub missing_keywords: Vec<String>,
}
```

Immutable. A re-run produces a new hash; nothing is regenerated in place.

## Storage layout (server)

```
~/.dreamjob/
  config.yaml                   # server settings — bind address, intervals (19)
  sources.yaml                  # which boards to poll (19)
  dreamjob.db                   # SQLite
  profile.yaml                  # the Profile, user-owned
  answers.yaml                  # the AnswerBook — form answers, user-owned (14)
  accounts.yaml                 # SiteAccount mirror, human-readable (15)
  sites.yaml                    # browser-agent allowlist + recipe status (14)
  master-resume.md              # extracted text of resumePath
  metrics.md                    # numbers the user has supplied, reused across applications
  artifacts/
    resume-8f3a91c2.{pdf,docx,json,md}   # content-addressed, immutable (17)
  applications/
    01J.../                     # one dir per Application.id
      posting.md                # the posting text, frozen at apply time
      keywords.md
      bullets-rewritten.md
      cover-letter.md
      resume.pdf                # hardlink into artifacts/
      receipt.json
      browser/                  # plan.json, filled.json, trace.zip, step-*.png (14)
      transcript-*.jsonl
  browser/
    acme.wd1.myworkdayjobs.com/ # persistent browser profile per tenant (15)
  mail/                         # attributed messages (16)
  logs/
```

Everything under this tree is gitignored and private. The phone holds a **cache only** — deck, recent applications, and pending swipes; never the master resume, never a credential, never a browser profile. See [09](09-compliance.md).

Secrets are the one thing *not* in this tree: passwords and OAuth tokens live in the OS keychain ([15](15-accounts-identity.md)).

## Open questions

- Should `Profile` support multiple named profiles ("backend roles" vs "platform roles") with separate decks? Cleaner than one profile with wide `roles`, but multiplies matcher state.
- Company size and funding aren't in any board API. Is `companyFit` worth having before there's a data source for it?
- Does `save` (swipe up) deserve its own queue, or is it just a right-swipe the user hasn't committed to?
- Should the phone cache `descriptionHtml` at all, or fetch full descriptions on demand? Caching it makes offline browsing real and roughly triples the cache size.
- `BrowserRun.fields` duplicates what the Playwright trace already holds. Is the structured copy worth it, or should the review screen read the trace?
- The Rust shapes here are the reference, but Go is what actually writes to SQLite. Does `sqlc` generate a third set of structs that then need mapping, or do the DB rows and the contract types stay deliberately identical?
- Newtypes (`Sha256`, `CountryCode`, `CredentialRefId`) are free in Rust and awkward in Go, where the idiom is a bare `string`. Are they worth defining on the Go side anyway, or does the safety stop at the core boundary?
- Should `MailMessage` bodies live in SQLite or on disk like the other artifacts? They are small and queryable, which argues for the DB; they are as sensitive as the resume, which argues for the tree.
