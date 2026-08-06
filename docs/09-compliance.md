# 09 — Compliance & privacy

**Status: specified.** These are constraints on every other doc. Where this doc conflicts with a feature, this doc wins.

## Two regimes

Reading job postings and applying to jobs are different acts and they get different rules. Conflating them is how this doc would end up either forbidding the product or permitting a scraper.

| | **Ingestion** — reading postings | **Submission** — applying |
| --- | --- | --- |
| Who is acting | A bot, at scale, on the public web | The user, once, to one employer who asked for applications |
| Volume | Thousands of postings | ~20 a week, capped at 5/hour |
| Authentication | **Never.** Public endpoints only | **Allowed**, as the user, in the user's own accounts |
| Human involvement | None needed | A human clicks submit, every time, through M6 |
| Evasion | Forbidden | Forbidden — identically |

The line this doc draws is **not** "never drive a browser". It is: never pretend to be a human to a system that is trying to exclude bots, never act at a volume the channel wasn't built for, and never send something a human hasn't read. Filling a form the employer published *for candidates to fill*, as the candidate, with the candidate watching, is on the right side of that line. Scraping a logged-in feed is not.

## Source terms

| Source | Ingest | Submit | Basis |
| --- | --- | --- | --- |
| Greenhouse, Lever, Ashby, Workable | Yes — public job-board APIs | Yes — documented application endpoints, API first | The platforms publish these endpoints for exactly this |
| Company career pages | Yes, with `robots.txt` respected and rate limits | Yes — browser form fill with a human-pressed submit ([14](14-browser-agent.md)) | Public pages for crawling; the apply form is published for candidates to fill |
| Workday, iCIMS, SuccessFactors, Taleo | Per-tenant, where the board is public | Yes — browser, with a per-tenant candidate account ([15](15-accounts-identity.md)) | No application API exists; the web form is the only channel offered |
| LinkedIn | **No** | **Never** | Official APIs are gated; automating Easy Apply violates the User Agreement and gets accounts banned |
| Indeed | **No** | **Never** | Same |

**LinkedIn and Indeed are not a backlog item.** They are excluded by decision. A banned account costs the user more than the automation saves, and the exclusion is not reopened by a workaround becoming technically available. If a source gates its API, the answer is to not use that source — not to scrape around the gate. What *is* supported — the user's own data export, profile keyword work, referral drafting, and skipping "Apply with LinkedIn" buttons in favour of the real form — is specified in [15](15-accounts-identity.md).

## Rules for any new ingestion source

Before an adapter is written, all five must hold:

1. **Terms permit it.** Read the actual ToS, not a summary. Record the date read and the relevant clause in the adapter.
2. **`robots.txt` permits it.** Checked at ingest time, not just at adapter-authoring time, and honoured including `Crawl-delay`.
3. **No authentication as a user.** No session cookies, no logged-in scraping, no credential storage. Public endpoints only. **This rule is scoped to ingestion** — submission is governed by the section below.
4. **No evasion.** No CAPTCHA solving, no IP rotation, no user-agent spoofing to look like a browser, no fingerprint randomization. If a site is trying to keep automation out, it succeeded.
5. **Identifiable traffic.** A real User-Agent naming the project and a contact URL, so an operator who wants it to stop can ask.

If any check fails, the source is a manual bookmark — the user opens it themselves. That is an acceptable outcome.

## Rules for authenticated submission

Before the browser agent runs against a domain, all seven must hold. These are the conditions under which rule 3 above is relaxed, and they are not individually negotiable.

1. **The employer published the form for candidates.** An apply form is an invitation. A logged-in search page is not.
2. **The account is the user's, created with the user's knowledge**, one human-approved registration at a time ([15](15-accounts-identity.md)). No accounts on anyone else's behalf, ever.
3. **A human presses submit.** Every application, through M6. Unattended submission is unspecified and gated behind conditions listed in [14](14-browser-agent.md) §5, not behind a config flag.
4. **No evasion, unchanged.** A CAPTCHA halts the run and is solved by the user or not at all. No stealth plugins, no fingerprint spoofing, no proxies. A real, current, unmodified browser.
5. **The domain is on the allowlist** in `sites.yaml`, with its terms read and the date recorded. `blocked` and `manual-only` are sticky and only a human moves them back.
6. **`robots.txt` is honoured on the apply path too.** A site that disallows its own apply URLs gets a manual draft.
7. **Volume caps are identical to the API path.** 5 submissions an hour, ~20 a week. Browser support widens *which* jobs are reachable, never how many are sent — the volume argument in the section below is unaffected by it.

Failing any of these is not a blocker to be worked around; it means that site is a manual draft, which is a 30-second cost to the user.

## Credentials and secrets

The system now holds passwords, session cookies and an OAuth token to the user's mailbox. That is a materially larger blast radius than a resume, and it gets its own rules ([15](15-accounts-identity.md), [16](16-mailbox.md)):

1. **Secrets live in the OS keychain, never in SQLite, a dotfile, or a config file.** No keychain, no stored credentials — the site drops to `manual-only`.
2. **The model never sees a secret.** Not in a prompt, not in a tool result, not in a transcript. The browser plan carries a credential *reference*; the sidecar resolves it after the model's last turn.
3. **Generated passwords only.** 32 random characters, unique per site. The user's real passwords are never accepted or stored.
4. **Traces are scrubbed.** Any recorded input to a `type=password` field is removed before a Playwright trace is written to disk.
5. **Verification codes are never persisted** — not in the DB, not in logs, not in transcripts. Only that a challenge occurred, for which domain, and its outcome.
6. **Browser profiles are credential-grade.** Cookies in `~/.dreamjob/browser/` authenticate as the user; they are gitignored, never backed up off-machine, and never synced to the phone.
7. **The browser sidecar binds `127.0.0.1` only.** Unlike the JSON API it is never exposed to the LAN — it holds live authenticated sessions to employer systems.
8. **Mailbox scopes are minimal and read-only**: `gmail.readonly`, never `gmail.send`, never full mailbox access. Queries are derived from the user's own applications and are logged.

## Rate limits and etiquette

- Per-source `requestsPerMinute` and `concurrency` are declared by the adapter and enforced by the runner, never by the adapter itself.
- Default: 30 req/min, concurrency 2, per source. Career-page scraping: 6 req/min, concurrency 1.
- Exponential backoff on 429 and 5xx, with a hard stop after 5 consecutive failures and an alert to the user.
- Conditional requests (`If-Modified-Since`, ETag) wherever supported, and `since` filters wherever the API offers one.
- Polling intervals ([04](04-aggregation.md)) are floors, not targets. A job board does not need to be checked every 10 minutes.
- Submission is capped at 5/hour regardless of queue depth.

## Application volume

The quality bar in [01](01-product-spec.md) is also an ethics position. Employers absorb the cost of every application; flooding an ATS with generated applications degrades the channel for everyone and is exactly what filters are tuned to catch. Target: ~20 strong tailored applications a week. Any feature that raises volume at the expense of per-application quality is rejected on those grounds, not just product ones.

## Truthfulness

Every application this system produces represents the user to a real employer. A fabrication discovered later is a fireable offence and the system's fault.

Hard rules, enforced in the skills ([08](08-resume-skills.md)) and at the review gate ([07](07-apply-pipeline.md)):

1. No invented metrics, employers, dates, titles, or technologies. Ask, or use a `[verify before sending]` placeholder.
2. Placeholders block approval. An unfilled placeholder can never reach an employer.
3. No keyword the user's real work can't support. Gaps are learning targets, not resume edits.
4. No keyword stuffing, hidden text, or white-on-white text. These are fraud attempts against the ATS and are detected.
5. Every claim must be defensible in an interview. That is what `resume-hiring-manager` tests.
6. Applications are sent as the user, by the user's decision. Nothing in the system presents itself as a different person.
7. **Form answers are the user's answers.** The model maps a form field to a key in the `AnswerBook`; it never composes a value ([14](14-browser-agent.md)). An unmapped required field halts the run and is answered by the user.
8. **Voluntary self-identification is never answered by the model.** Gender, race, veteran and disability questions default to *decline to self-identify*. Only the user may set a real value, and nothing may change one.
9. **Salary expectation is never inferred.** If a form requires a number the user hasn't set, that is a halt, not an estimate.

Whether to disclose AI assistance in an application is the user's call and varies by employer. The system does not insert or remove such disclosure on its own.

## Personal data

**What's held.** A resume — one of the densest PII documents most people own: full name, address, phone, email, employment history, education, sometimes date of birth or nationality. Plus every application sent and every job considered, every form answer the user has ever given, dozens of employer-system accounts, live browser sessions, and a read grant on the user's mailbox.

The last four arrived with [14](14-browser-agent.md)–[16](16-mailbox.md) and they change the threat model, not just its size: before them, a compromised machine leaked a document the user hands to strangers anyway. Now it leaks accounts and an inbox. Hence the keychain, the loopback-only sidecar, and the scoped mailbox queries.

### Device pairing and the LAN

The Flutter app runs on a phone, so the backend cannot hide behind `127.0.0.1`. That is a real widening of the attack surface and it gets explicit rules:

1. **Bind to the LAN interface, never `0.0.0.0` on an untrusted network.** The server refuses to start on a public interface without an explicit override flag.
2. **Every request carries a bearer token.** No unauthenticated endpoint exists — not even a health check that leaks whether dreamJob is running.
3. **Pairing is out-of-band.** The server prints a QR code containing host, port, and token; the app scans it once and stores the token in `flutter_secure_storage` (Keychain / Keystore). The token is never typed, mailed, or committed.
4. **Rotation is one command**, and rotating invalidates every paired device.
5. **TLS with a self-signed cert, pinned by the app at pairing time.** Plain HTTP carries a resume and a bearer token across a network the user may not control; on a café Wi‑Fi that is a live credential-and-PII leak. If TLS is genuinely too much for a first cut, the app MUST refuse to connect over anything but a private-range address and say why.
6. **No hosted deployment without revisiting this section.** Putting the server on a VPS moves the resume off the user's machine and changes the whole privacy story below. That is a decision, not a deployment detail. One revisit has been done — [the `air` box](server.md), user-owned hardware on a private overlay, permitted under five stated conditions. A VPS is still not, and the difference is who can read the disk.

### Rules

1. **Local by default.** The database, profile, resume, and application artifacts live on the user's own machine. No sync service, no telemetry, no hosted backend. The phone holds a **cache only** — deck, recent applications, and pending swipes — never the master resume, never the API key. A lost phone loses nothing of consequence and can be de-paired by rotating the token.
2. **Gitignored.** `resume-workspace/`, `applications/`, `artifacts/`, `browser/`, `mail/`, `answers.yaml`, `accounts.yaml`, `*.pdf`, `*.docx`, `LOCAL_CONTEXT.md`, and the database are all excluded from version control. The existing [`.gitignore`](../.gitignore) covers the skill workspace and the credential-adjacent files; the rest of the app's storage tree must be added when it exists.
3. **Third parties are the model provider, the employer, and the mailbox provider the user already uses.** Resume text goes to the model provider during tailoring and to the employer the user chose. No analytics vendor, no enrichment service, no aggregator, no CAPTCHA service, no SMS gateway gets a copy.
4. **Secrets outside the repo.** The Anthropic API key comes from the environment on the server. Site passwords and the mailbox OAuth token come from the OS keychain. None of them appears in `profile.yaml`, none travels to the phone, and no LLM call originates from the app.
5. **Deletion works.** Deleting the server's storage tree deletes everything except the keychain items, which a single `dreamjob purge-credentials` removes; uninstalling the app clears its cache and the paired token. No hidden caches elsewhere. Deleting a `SiteAccount` removes its keychain item and its browser profile together.
6. **Logs are data too.** Agent transcripts contain the full resume; browser traces contain the resume, the form answers, and the employer's pages. They live under the same tree, under the same rules, and are never shipped anywhere.
7. **The mailbox is read-only and scoped.** dreamJob never sends mail as the user, never requests a send scope, and only queries domains the user has already applied to ([16](16-mailbox.md)).

**If dreamJob ever becomes multi-user**, this section is void and must be rewritten first: tenant isolation, encryption at rest, a retention policy, a deletion path, and a lawful basis under GDPR for holding someone else's employment history. Do not add a login screen without doing that work.

## Automated decision-making

The matcher decides which jobs the user sees. That is a filter on the user's own opportunities, applied by their own tool, at their own request — but it is still a decision made on their behalf, and the failure mode is invisible: a job filtered out is a job that never existed as far as the user knows.

Mitigations, all specified elsewhere and collected here because they matter as a group:

- Hard filters are conservative and recorded per posting in `filter_failures[]` ([05](05-matching.md)).
- Every card shows why it's in the deck ([06](06-swipe-ui.md)).
- The learned component is a logistic regression with inspectable coefficients, capped at 0.20 weight, resettable without touching the profile, and required to explain itself in `reasons[]` ([05](05-matching.md)).
- Exploration re-injects cards from categories the learned model has driven to zero, so a wrong inference can be corrected by evidence rather than compounding.

## Open questions

- Self-signed TLS plus pinning is the right call on paper, but it is real work and a real source of confusing failures. Is a private-range-only guard an acceptable first cut, and for how long?
- Should the system record the ToS-read date per adapter in code, or in a reviewable registry file? A stale terms read is a real risk over a project's life.
- Is a "what got filtered out today" view a compliance feature (transparency) or an anxiety feature? [05](05-matching.md) raises it as product; it is arguably both.
- Retention: keep closed postings and old applications forever as M7 training data, or expire them?
- The two-regimes split rests on "a human presses submit". If M7 ever proposes unattended submission, does the whole authenticated-submission section have to be rewritten, or is a per-site opt-in with a proven recipe genuinely equivalent? Assume the former until argued otherwise.
- Should the browser agent identify itself at all? An honest User-Agent is required for ingestion, but a modified User-Agent on a real browser session is closer to spoofing than to disclosure, and disclosing "a bot filled this form" to an ATS may get a legitimate application discarded. Currently: leave the browser's real UA untouched and disclose nothing, which is neither hiding nor announcing.
- Does a dedicated job-search mailbox ([16](16-mailbox.md)) reduce the privacy surface enough to be the recommended default rather than an option?
