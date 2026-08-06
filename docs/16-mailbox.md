# 16 — Mailbox integration

**Status: specified.** M5a for verification codes, M6 for outcomes.

The mailbox is where the job search actually happens after the submit button. Two jobs, one integration:

1. **Verification codes** during account registration ([15](15-accounts-identity.md)) — blocking, latency-sensitive, deterministic.
2. **Outcome detection** — confirmations, rejections, screening invitations, interview requests — which is the tracking data [10](10-roadmap.md) M6 needs and the only honest training signal for M7.

A mailbox is a more sensitive grant than a resume. The resume is a document the user hands to strangers by design; the inbox is everything else in their life. That asymmetry drives every rule below.

## Access

**Gmail API over OAuth 2.0**, desktop-app flow with a loopback redirect. No password, no IMAP app-password for Gmail, no "less secure apps".

| Scope | Granted | Why |
| --- | --- | --- |
| `gmail.readonly` | Always | Reads messages. Sufficient for both jobs |
| `gmail.modify` | Opt-in only | Applying a `dreamJob/Applications` label. Off by default; the feature is cosmetic |
| `gmail.send` | **Never** | dreamJob does not send email as the user. Follow-ups are drafted for the user to send, never sent |
| `https://mail.google.com/` | **Never** | Full mailbox control, including delete. There is no feature that justifies it |

Tokens live in the OS keychain alongside site credentials ([15](15-accounts-identity.md)), never in `profile.yaml`, never on the phone. The refresh token is the most valuable secret in the system after the resume itself.

**Non-Gmail providers:** IMAP with an app-specific password, same keychain, same filters, same read-only posture — `SELECT` only, never `STORE`, never `EXPUNGE`. The provider abstraction is one Dart interface:

```dart
abstract class MailboxAdapter {
  /// Messages matching [query] since [since]. Never a full-mailbox fetch.
  Stream<MailMessage> search(MailQuery query, {DateTime? since});

  /// Incremental sync. Gmail uses historyId; IMAP uses UIDNEXT.
  Future<SyncCursor> syncFrom(SyncCursor cursor);
}
```

## Scoped reading, not mailbox surveillance

dreamJob never reads the mailbox. It reads a narrow, computable slice of it.

Every query is the conjunction of three constraints:

1. **Time.** Nothing older than the first application, and for challenges, nothing outside the challenge window.
2. **Sender.** The domain must be in the derived allowlist: employer domains from `Application`, plus known ATS notification senders (`greenhouse.io`, `hire.lever.co`, `ashbyhq.com`, `workable.com`, `myworkday.com`, `icims.com`, `successfactors.com`).
3. **Recipient.** For plus-tagged aliases ([15](15-accounts-identity.md)), the `Delivered-To` tag must match a known alias.

```
newer_than:90d (from:greenhouse.io OR from:hire.lever.co OR from:acme.com …) -in:spam
```

The allowlist is **derived, never manual** — it is exactly the set of domains the user already applied to. A domain enters it by the user right-swiping a job at that company, and nothing else. There is no code path that widens it, and the query is logged per sync so the user can see what was asked for.

## Verification challenges

Opened by a registration or login run ([15](15-accounts-identity.md)), never spontaneously.

```
sidecar hits "we emailed you a code"
   ▼
VerificationChallenge{ kind: emailCode, domain, openedAt, expiresAt: +5min }
   ▼
poll mailbox every 5s, window = [openedAt - 60s, expiresAt], sender = domain or its ATS
   ▼
extract by regex ──> deliver to sidecar ──> typed ──> challenge closed
```

**Rules**

1. **Extraction is a regex, not a model call.** `\b\d{4,8}\b` in the message's first 500 characters, plus per-platform patterns in the recipe. A model that reads verification emails is a model with an inbox; deterministic extraction keeps the mailbox out of every prompt.
2. **Magic links are followed only if the link host matches the domain of the run in progress.** A link to any other host is refused and escalated to the human. This is the whole defence against a mail-triggered redirect being clicked by an automated browser.
3. **One challenge open at a time**, system-wide. Two concurrent registrations cannot cross-consume each other's codes.
4. **Codes are never persisted.** Not in the DB, not in the trace, not in a log line. The `VerificationChallenge` row records that a challenge happened, its domain and its outcome — never its value.
5. **Expiry is real.** After `expiresAt` the challenge fails to `needs_attention` and the code, if it arrives late, is ignored rather than replayed.
6. **A challenge the system did not open is never answered.** Unsolicited verification mail is a signal that something is wrong, and it surfaces to the user as a warning rather than being consumed.

## Outcome detection (M6)

Every submitted application gets a mailbox watch. This closes the loop [01](01-product-spec.md) needs for its reply-rate metric.

**Attribution**, in order of confidence:

| Signal | Confidence | Source |
| --- | --- | --- |
| Plus-tag in `Delivered-To` matches a `SiteAccount` alias | Exact | [15](15-accounts-identity.md) |
| ATS thread id / `List-Id` matches a stored receipt | Exact | `receipt.json` |
| Sender domain matches the application's company domain, within 60 days of submission | Strong | Derived |
| Company name in subject or body, no domain match | Weak — **suggested, not applied** | Surfaced to the user for one tap |

Weak matches never write an `Outcome` on their own. A mis-attributed rejection silently poisons the M7 training set, and the failure is invisible.

**Classification** is rules-first, model-second:

1. Deterministic patterns catch most of it: "unfortunately", "not moving forward", "we've decided" → `rejected`; "schedule", "calendly", "availability" → `screen`; "offer" → the model does *not* get to decide this one, the user confirms it.
2. Anything the rules can't classify goes to the model — **one message, trimmed, one at a time**, returning an `OutcomeKind` and nothing else. It never sees the rest of the mailbox and never sees a message outside the allowlist.
3. Every classification is reversible in one tap in the tracker, and the correction is what gets stored.

**Confirmation-of-receipt** is the second signal the browser agent needs for `submitted` ([14](14-browser-agent.md)): an ATS acknowledgement from the employer's domain within 15 minutes of a submit.

## Storage

`MailMessage` rows hold headers, the plain-text body, the resolved `applicationId`, and the classification — under `~/.dreamjob/`, same tree, same rules, same gitignore ([09](09-compliance.md)).

Bodies are stored because an interview invitation the user can't re-read is useless, and because a mis-classification is undiagnosable without the text. They are **not** stored for messages that matched no application: an unattributed message is counted and discarded, never retained.

Attachments are never downloaded.

## Privacy posture

The rules that make this grant defensible, collected in one place because a reviewer will look for exactly this list:

1. Read-only by default; `gmail.send` is never requested; full-access scopes are never requested.
2. Queries are derived from the user's own applications and are logged.
3. Verification codes are extracted by regex and never persisted.
4. The model sees at most one already-attributed message at a time, and only for classification.
5. Nothing leaves the machine. The mailbox is never synced to the phone; the app sees classified outcomes, not messages.
6. Revocation is one command locally and one click in the Google account console, and dreamJob keeps working without a mailbox — degraded to manual outcome entry, which is what M6 does anyway before this ships.
7. Disconnecting the mailbox deletes the stored messages and the token together.

## Failure modes

| Failure | Response |
| --- | --- |
| OAuth token expired or revoked | Stop syncing, surface a reconnect prompt. Never fall back to asking for a password |
| Code never arrives within the window | Challenge fails; `needs_attention`; the user can paste the code manually into the app |
| Code arrives after expiry | Ignored. A stale code typed into a new form is a lockout risk |
| Gmail API quota exceeded | Back off; verification challenges take priority over outcome sync |
| Message attributed to the wrong application | One-tap correction in the tracker; the correction is stored and the weak-match rule that produced it is logged |
| Mailbox unavailable at submit time | Browser agent falls back to the page-only confirmation signal ([14](14-browser-agent.md)) |

## Open questions

- Is a dedicated job-search mailbox (a separate Google account used only for applications) a better default than scoping a personal one? It sidesteps most of this doc's privacy surface and costs the user one setup step.
- Should outcome classification run on a schedule (daily) or on-open? Daily is simpler; on-open avoids reading anything the user never asked about.
- Does `gmail.modify` labelling earn its extra scope, or is a local view enough?
- Interview invitations contain times and links. Is extracting them into the tracker useful, or does that drift toward the calendar/scheduling features [01](01-product-spec.md) declares out of scope?
