# 03 — Data model

**Status: specified.** Types are Dart. They live in the `dreamjob_shared` package and are compiled into both the server and the Flutter app, so the API contract cannot silently drift.

Classes are written plainly below; the real definitions use `freezed` + `json_serializable` for immutability, `copyWith`, equality, and JSON codecs.

Entities: `JobPosting`, `Profile`, `Match`, `SwipeEvent`, `Application`, plus the account/browser/mailbox/artifact types added by [14](14-browser-agent.md)–[17](17-resume-artifacts.md).

## Shared enums

```dart
enum SourceId { greenhouse, lever, ashby, workable, careersPage }

enum WorkMode { remote, hybrid, onsite, unknown }

enum Seniority { intern, junior, mid, senior, staff, principal, unknown }

enum EmploymentType { fullTime, partTime, contract, internship, unknown }
```

`unknown` is a first-class value everywhere. Postings routinely omit work mode and seniority, and a matcher that guesses silently is a matcher that lies. Unknowns are scored explicitly ([05](05-matching.md)), never coerced to a default.

## JobPosting

One row per real-world job, not per source listing. Cross-posts collapse into `sources`.

```dart
class JobPosting {
  final String id;                  // ULID, ours, stable across re-ingests
  final String fingerprint;         // dedup key — see 04
  final List<PostingSource> sources; // >=1; the same role seen on several boards

  final String title;
  final String titleNormalized;     // lowercased, seniority and noise stripped
  final Company company;

  final WorkMode workMode;
  final List<Location> locations;   // as posted; may be several
  final RemoteScope? remoteScope;

  final Seniority seniority;
  final EmploymentType employmentType;
  final Compensation? comp;
  final List<String> stack;         // normalized tags: 'go', 'kubernetes', 'postgres'

  final String descriptionText;     // plain text — what the matcher and agent read
  final String? descriptionHtml;    // preserved for the UI
  final List<String> requirements;  // extracted bullets, source wording kept
  final Dealbreakers dealbreakers;

  final DateTime? postedAt;         // as claimed by the source
  final DateTime firstSeenAt;
  final DateTime lastSeenAt;
  final DateTime? closedAt;         // set when it disappears from its board

  final int normalizerVersion;
}

class PostingSource {
  final SourceId source;
  final String sourceJobId;
  final String board;               // greenhouse token, lever slug, hostname…
  final String url;                 // canonical posting page
  final String applyUrl;
  final Map<String, dynamic> raw;   // untouched source payload — never rewritten
  final DateTime fetchedAt;
}

class Company {
  final String name;
  final String nameNormalized;
  final String? domain;
  final String? logoUrl;
}

class Location {
  final String raw;                 // exactly as posted: "Remote - EMEA", "NYC (Hybrid)"
  final String? city;
  final String? region;
  final String? country;            // ISO 3166-1 alpha-2
  final String? timezone;           // IANA
}

class RemoteScope {
  final bool anywhere;
  final List<String> countries;     // ISO 3166-1 alpha-2
  final (int, int)? timezoneRange;  // UTC offsets, inclusive
}

enum CompPeriod { year, month, hour }
enum CompSource { posted, rangeInText, absent }

class Compensation {
  final num? min;
  final num? max;
  final String currency;            // ISO 4217
  final CompPeriod period;
  final bool equityMentioned;
  final CompSource source;
}

/// `null` means the posting did not say. Never coerce that to `false`.
class Dealbreakers {
  final bool? visaSponsorship;
  final bool? securityClearance;
  final bool? onCall;
  final int? minYearsExperience;
  final List<String>? citizenshipRequired;
}
```

**Rules**

- `raw` MUST be stored verbatim per source. Re-normalizing without re-fetching depends on it.
- `descriptionText` MUST be the text the matcher and the agent both read. Two different extractions of the same posting is a class of bug worth designing out.
- `CompSource` distinguishes a posted range from one scraped out of prose. Never present an inferred range as posted.
- Deleting a posting is not a thing. One that vanishes from its board gets `closedAt` and stays.

## Profile

The single file that drives matching. Human-editable — a document the user owns, not app state. Stored as `profile.yaml` on the server and loaded into this shape; the app edits it through the API.

```dart
class Profile {
  final int version;                // bumped on every edit; Match rows reference it

  final List<String> roles;         // 'backend', 'platform', 'sre', 'data'
  final List<Seniority> seniority;  // acceptable band

  final List<WorkMode> workModes;
  final int? maxCommuteMinutes;     // hybrid/onsite only
  final Location? baseLocation;
  final RemotePreference remote;

  final CompFloor? compFloor;
  final bool compFloorAppliesToUnposted;

  final StackPreference stack;
  final ProfileDealbreakers dealbreakers;

  final String resumePath;          // master resume, the tailoring baseline
  final MatchWeights? weights;      // optional override of the defaults in 05
}

class RemotePreference {
  final List<String> countries;
  final (int, int)? timezoneRange;
}

class CompFloor {
  final num amount;
  final String currency;
  final CompPeriod period;
}

class StackPreference {
  final List<String> want;          // scored positively
  final List<String> ok;            // neutral
  final List<String> refuse;        // hard filter
}

class ProfileDealbreakers {
  final bool needsVisaSponsorship;
  final bool noOnCall;
  final bool noClearance;
  final List<String> companyBlocklist; // normalized company names
  final int? minCompanySize;
  final int? maxCompanySize;
}
```

A profile edit bumps `version`, which invalidates existing `Match` rows rather than mutating them.

## Match

The matcher's verdict on one posting under one profile version.

```dart
class Match {
  final String postingId;
  final int profileVersion;
  final int matcherVersion;

  final double score;               // 0–100
  final bool passedFilters;         // false => hard-filtered, never shown
  final List<String> filterFailures; // e.g. ['workMode', 'compFloor']

  final MatchComponents components;
  final List<String> reasons;       // human-readable, shown on the card
  final DateTime computedAt;
}

class MatchComponents {
  final double roleFit;
  final double stackFit;
  final double seniorityFit;
  final double locationFit;
  final double compFit;
  final double companyFit;
  final double learned;             // from swipe history; 0 until M7
}
```

`reasons` is a product feature, not a debug field. A card that can't say why it's in the deck erodes trust in the deck.

## SwipeEvent

Append-only. Training data for M7 and the audit trail for "why did I apply here".

```dart
enum SwipeDirection { right, left, save }

class SwipeEvent {
  final String id;                  // client-generated, so offline replay is idempotent
  final String postingId;
  final SwipeDirection direction;
  final DateTime at;
  final int dwellMs;                // card shown → swiped; a proxy for deliberation
  final int cardVersion;            // which card layout they saw
  final double matchScore;          // score at swipe time, denormalized on purpose
  final int profileVersion;
  final String? reason;             // optional: "too junior", "bad stack"
  final String? compensates;        // id of the event this undoes
}
```

Undo appends an event with `compensates` set. Nothing is deleted; the deck's current state is a fold over the log. Because the app can swipe offline, `id` is minted client-side — the server treats a re-sent id as a no-op.

## Application

One per right-swipe that entered the pipeline.

```dart
enum ApplicationStatus {
  queued,
  tailoring,
  awaitingReview,
  approved,
  submitting,
  awaitingVerification,   // parked on an email/SMS challenge — see 15, 16
  submitted,
  submitUnverified,       // form was sent, neither confirmation signal landed — see 14
  awaitingManualSubmit,
  submitFailed,
  needsAttention,
  abandoned,
  responded,
  rejected,
  interviewing,
  closed,
}

class Application {
  final String id;
  final String postingId;
  final String swipeEventId;
  final ApplicationStatus status;

  final String workspacePath;       // applications/<id>/
  final ApplicationArtifacts artifacts;

  final List<AgentRun> agentRuns;
  final DateTime? approvedAt;
  final String approvedBy;          // literal 'human'; no other legal value through M6
  final DateTime? submittedAt;
  final SubmitMethod? submitMethod;

  final Outcome? outcome;
  final DateTime? followUpAt;
}

class ApplicationArtifacts {
  final String? keywordsMd;         // resume-recruiter output for this posting
  final String? bulletsMd;          // resume-rewriter output
  final String? resumePdf;          // rendered — the file actually sent
  final String? resumeSha256;       // hash of that file, re-verified at upload — see 17
  final String? resumeDocx;         // only when the form demands it
  final String? coverLetterMd;
  final String? submissionReceipt;
  final String? browserRunId;       // set when submitMethod == browser
}

enum SubmitMethod { api, browser, manual }

enum OutcomeKind { noResponse, rejected, screen, interview, offer }

class Outcome {
  final DateTime? firstResponseAt;
  final OutcomeKind kind;
  final String? notes;
}

enum AgentStage { recruiter, rewriter, coverLetter, formMapping }

class AgentRun {
  final AgentStage stage;
  final DateTime startedAt;
  final DateTime? endedAt;
  final bool ok;
  final String? error;
  final String? transcriptPath;
}
```

**Rules**

- `approvedAt` is required before `submitting`. Enforced in the submitter, not the UI.
- `artifacts.resumePdf` is the exact file sent. It is never regenerated in place — a follow-up tailoring run writes a new file.
- Status transitions are one-way except `queued ⇄ tailoring` (retry), `submitting ⇄ awaitingVerification` (a challenge parks and resumes the run), and the terminal outcome states.

## SiteAccount and CredentialRef

Accounts dreamJob holds at employer systems ([15](15-accounts-identity.md)). The secret is not in this model — that is the point of it.

```dart
enum SiteAccountKind { atsTenant, atsGlobal, careerPage }
enum EmailStrategy { plusTag, plain, catchAll }

class SiteAccount {
  final String id;
  final String domain;              // apply domain, e.g. acme.wd1.myworkdayjobs.com
  final SiteAccountKind kind;
  final String platform;            // 'workday', 'greenhouse', 'icims', 'custom'

  final String email;               // the alias used to register
  final EmailStrategy emailStrategy;
  final String credentialRefId;     // keychain handle — never a secret
  final String browserProfilePath;  // persistent user-data-dir

  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool phoneVerified;
  final int applicationCount;
}

class CredentialRef {
  final String id;
  final String service;             // always 'dreamjob'
  final String username;
  final DateTime createdAt;
  final DateTime? rotatedAt;
}
```

**Rules**

- A `CredentialRef` MUST NOT have a `secret` field, in this model or in the database schema. The keychain is the only store.
- No secret, session cookie, or browser profile ever appears in an API response the phone can read.
- `browserProfilePath` contents are credential-grade: cookies there authenticate as the user.

## BrowserRun

One per browser-driven submission or registration attempt ([14](14-browser-agent.md)).

```dart
enum BrowserRunKind { register, login, dryRun, submit }
enum BrowserRunOutcome { succeeded, halted, failed, blocked }
enum FillTier { recipe, semanticMap, human }

class BrowserRun {
  final String id;
  final String? applicationId;      // null for a bare register/login run
  final String siteAccountId;
  final BrowserRunKind kind;

  final String recipeId;
  final int recipeVersion;
  final FillTier highestTierUsed;   // recipe-only runs are the trustworthy ones

  final List<FilledField> fields;
  final BrowserRunOutcome outcome;
  final String? haltReason;         // quoted question, CAPTCHA, mismatch…
  final String tracePath;           // trace.zip + screenshots
  final String? confirmationPath;

  final DateTime startedAt;
  final DateTime? endedAt;
  final String? confirmedBy;        // 'human' — the submit gate token holder
}

class FilledField {
  final String selectorOrRef;
  final String? answerKey;          // AnswerBook key; null for uploads
  final String renderedValueHash;   // never the value for anything sensitive
  final String readBackValue;       // what the DOM held afterwards
  final bool verified;              // rendered == readBack
  final FillTier tier;
}
```

**Rules**

- `outcome == succeeded` requires `confirmedBy == 'human'` on a `submit` run. Enforced in the submitter.
- A run with any `verified == false` field MUST NOT reach the submit gate.
- Password fields are recorded as `FilledField` with `renderedValueHash` only, and are scrubbed from the trace.

## VerificationChallenge

```dart
enum ChallengeKind { emailCode, emailLink, sms }
enum ChallengeOutcome { resolved, expired, refused, cancelled }

class VerificationChallenge {
  final String id;
  final String browserRunId;
  final String domain;              // who asked — shown to the user before they answer
  final ChallengeKind kind;
  final DateTime openedAt;
  final DateTime expiresAt;         // openedAt + 5 min
  final ChallengeOutcome? outcome;
}
```

**The code itself is never a field.** Not stored, not logged, not in a transcript ([16](16-mailbox.md)). At most one challenge is open system-wide.

## MailMessage

```dart
class MailMessage {
  final String id;                  // provider message id
  final String? applicationId;      // null until attributed
  final AttributionConfidence confidence;

  final String fromDomain;
  final String? deliveredToAlias;   // the plus-tag, when present
  final String subject;
  final String bodyText;
  final DateTime receivedAt;

  final OutcomeKind? classified;
  final bool classificationConfirmedByUser;
}

enum AttributionConfidence { exact, strong, weak }
```

**Rules**

- A message with `confidence == weak` MUST NOT write an `Outcome`; it is a suggestion until the user taps it.
- Messages matching no application are counted and discarded, never retained.
- Attachments are never downloaded.

## ResumeArtifact

Content-addressed renders ([17](17-resume-artifacts.md)).

```dart
class ResumeArtifact {
  final String sha256;              // identity — the filename is sha256[:8]
  final String pdfPath;
  final String? docxPath;
  final String jsonPath;            // the ResumeDoc that produced it
  final String markdownPath;
  final DateTime renderedAt;
  final bool roundTripVerified;
  final bool keywordsLanded;
  final List<String> missingKeywords;
}
```

Immutable. A re-run produces a new hash; nothing is regenerated in place.

## Storage layout (server)

```
~/.dreamjob/
  dreamjob.db                   # SQLite (drift)
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
- Should `MailMessage` bodies live in SQLite or on disk like the other artifacts? They are small and queryable, which argues for the DB; they are as sensitive as the resume, which argues for the tree.
