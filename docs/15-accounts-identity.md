# 15 — Accounts & identity

**Status: specified.** M5a — a prerequisite for [14](14-browser-agent.md), not a follow-on.

Half the ATS market makes you register before it will take an application. Workday creates a candidate account *per employer tenant*; iCIMS, SuccessFactors and Taleo do the same; Greenhouse and Ashby offer an optional candidate profile that autofills. That means dreamJob accumulates dozens of employer-scoped accounts, each with a password, an email address, and often a phone number to verify.

This doc specifies how those are created, where the secrets live, and who is allowed to see them. The short version: **the model never sees a password, and the human always resolves a verification challenge.**

## The registration flow

Registration is a separate run from applying. Bundling them means a failed signup leaves a half-filled application and an account in an unknown state.

```
apply run needs account
   │
   ▼
lookup SiteAccount(domain) ──── found + session valid ──> resume apply run
   │ not found
   ▼
register run
   ├─ generate email alias      (§ email identity)
   ├─ generate password         (§ the vault — model never sees it)
   ├─ fill signup form          (14, tier 1/2)
   ├─ HUMAN confirms signup     (same gate as submit)
   ├─ email verification        (16 — automatic, deterministic)
   ├─ phone verification        (§ phone — human, always)
   └─ store SiteAccount + CredentialRef
   ▼
resume apply run
```

**A registration is never silent.** The user approves each new employer account the same way they approve a submission — one screen, the domain, the alias about to be used, and what the account is for. Accounts created on someone's behalf without their knowledge is exactly the pattern this system must not have.

## The vault

Secrets live in the **OS keychain**, never in SQLite, never in `profile.yaml`, never in a dotfile.

| Platform | Backend | Access |
| --- | --- | --- |
| macOS | Keychain via the `security` CLI | `security add-generic-password -s dreamjob -a <accountId> -w` |
| Linux | Secret Service via `secret-tool` | Same shape |
| Neither available | **Refuse to store credentials.** The site drops to `manual-only` in the site registry | — |

The database holds a `CredentialRef` — an opaque id, the domain, the username, and a rotation date. It never holds the secret. A dump of `dreamjob.db` leaks which employers the user applied to, which is bad; it does not leak a single password, which would be worse.

**Rules**

1. **Passwords are generated, never chosen.** 32 characters, CSPRNG, unique per site. The user does not know them and does not need to — password recovery is the reset link in their mailbox.
2. **The model never sees a secret.** Not in a prompt, not in a tool result, not in a transcript. The browser plan carries `{"secret": "<credentialRefId>"}`; the sidecar resolves it against the keychain and types it. The resolution happens in the sidecar process, after the model's last turn.
3. **Secrets are never logged.** The Playwright trace ([14](14-browser-agent.md)) records DOM state — password fields are masked by the browser, but the sidecar MUST additionally scrub any recorded input event whose target is `type=password` before the trace is written to disk.
4. **Never reuse the user's real password**, anywhere, for anything. If the user offers one, refuse it.
5. **Rotation and revocation are the user's, not ours.** dreamJob lists its accounts and can open each site's password page; it does not attempt automated password rotation across dozens of employer systems.
6. **No account without a live site registry entry** whose terms have been read and recorded ([09](09-compliance.md)).

## Email identity

Every account needs an address, and the address is also how [16](16-mailbox.md) maps an inbound email back to an application.

**Plus-addressing by default.** `user+acme@gmail.com` for Acme's tenant. Gmail, Fastmail and most providers route it to the same inbox; the tag survives in `Delivered-To`, which makes attribution deterministic instead of a fuzzy match on the sender domain.

**Fallback chain**, because a meaningful minority of ATS forms reject `+` with a bogus "invalid email" error:

1. `user+<companyslug>@domain` — preferred.
2. `user@domain` — plain, if the form rejects the tag. Attribution then falls back to sender-domain matching, which is weaker and is recorded as such on the `SiteAccount`.
3. A catch-all domain (`<companyslug>@jobs.example.com`) if the user owns one — strictly better than both, and the reason the `emailStrategy` field is configurable rather than hardcoded.

Never a disposable-mailbox service. The employer needs to be able to reach the user for the next two years; a burner address is a self-inflicted wound, not a privacy win.

## Phone and SMS verification

**SMS codes are resolved by the human. Always. There is no automation path here and there should not be one.**

Virtual and VOIP numbers are widely blocked by ATS providers, buying a pool of numbers to route around that is exactly the evasion [09](09-compliance.md) forbids, and an employer that needs to phone the user needs to reach a phone the user actually has.

The flow uses the phone-first architecture the product already has:

```
sidecar hits an SMS challenge
   ▼
VerificationChallenge{kind: sms, domain, expiresAt: +5min}  → server
   ▼
in-app prompt on the Flutter app: "Acme Workday wants an SMS code"
   ▼
user reads their own SMS, types 6 digits into the app
   ▼
server → sidecar → typed into the form → run resumes
```

Rules:

- 5-minute TTL, one attempt to submit the code, then a new challenge. Codes are never persisted — not in the DB, not in a log, not in a transcript.
- The challenge names the domain that asked. The user is told who is asking before they type a code, because "type this code into the app" is otherwise a phishing shape.
- **The system never requests a code the user did not initiate.** A challenge can only exist inside an open registration or login run the user already approved.
- Voice-call verification, authenticator-app TOTP, and identity-document upload are all out of scope: hand the user the browser and let them finish it themselves ([14](14-browser-agent.md) tier 3).

Email codes are different and *are* automated — see [16](16-mailbox.md). The distinction is that the mailbox is a data source dreamJob already reads under an explicit grant, and the extraction is a regex against a challenge window the system itself opened.

## Sessions

A logged-in session is worth more than a password: it avoids re-verification and it is what makes the second application to the same employer cheap.

- One persistent browser profile per **tenant**, not per application: `~/.dreamjob/browser/<domain>/`. Workday tenants are per employer, so this is a real directory count — a hundred employers is a hundred profiles, each a few MB.
- Sessions are validated before an apply run by loading the account page and checking for a logged-in marker. A stale session triggers a login run, not a registration run — dreamJob MUST NOT create a second account because it failed to notice it had one.
- **Session storage is credential-grade.** Cookies in these profiles authenticate as the user. They live under the same tree and the same rules as the resume ([09](09-compliance.md)) and are excluded from version control and from any backup that leaves the machine.
- De-pairing or wiping dreamJob deletes the profiles. There is no session sync to the phone, ever.

## LinkedIn

The user asked for LinkedIn integration; here is exactly what is supported and what is not, with the reasoning, because this is the one integration where the tempting version is the one that gets an account banned.

### Supported

| Capability | Mechanism | Why it's fine |
| --- | --- | --- |
| **Import the user's own profile** | LinkedIn's official *Get a copy of your data* export (CSV/JSON archive), dropped into `~/.dreamjob/imports/` | It's the user's own data, obtained through the channel LinkedIn provides for it. No scraping, no session |
| **Profile keyword optimization** | The proposed `linkedin-profile` skill ([08](08-resume-skills.md)): same research as `resume-recruiter`, applied to the user's headline, About, and role descriptions. Outputs text the user pastes | Writing your own profile is not automating the platform |
| **Postings discovered on LinkedIn** | The user pastes a LinkedIn job URL; dreamJob resolves the employer and finds the same req on the company's ATS board, then applies there | The application goes to the employer's own system. LinkedIn is never fetched programmatically |
| **Referral and connection drafting** | For a queued application, the agent drafts a connection note or an outreach message to a person the user names. The user sends it themselves, in their own browser | dreamJob writes text; the human sends it. No LinkedIn automation exists in the codebase |

### Not supported, and not a backlog item

- **Easy Apply automation.** Violates the User Agreement, gets accounts banned, and — the product argument that stands even if the terms changed tomorrow — Easy Apply submits the resume LinkedIn has on file, not the one dreamJob just tailored to this posting. Automating it would bypass the entire value of the system.
- **Logged-in scraping of postings, people, or companies.** No session cookies, no `li_at`, no headless LinkedIn.
- **Connection requests, messages, or profile views sent by the agent.** Drafting yes, sending no.

### "Apply with LinkedIn" buttons on employer sites

These appear on ATS-hosted forms and are an employer-side convenience, not LinkedIn automation. The browser agent's rule is: **skip the button, fill the form.** The button imports the LinkedIn profile version of the user's history, which is not the tailored artifact this system exists to produce. Recipes MUST NOT map to it, and tier 2 MUST treat it as a decline.

The site registry carries `linkedinApplyPresent: true` as a note, because a site that *only* offers that path is a `manual-only` site.

## Greenhouse candidate account

Greenhouse is worth calling out separately because it is the M1 source and because its candidate profile ("My Greenhouse") is a single account that autofills across every Greenhouse-hosted board — one account, hundreds of employers, unlike Workday's one-per-tenant model.

| Use | Rule |
| --- | --- |
| Autofill identity fields (name, email, phone, location, links) | **Yes.** It's faster and less error-prone than tier-2 mapping, and the values come from the same `identity` block of the `AnswerBook` |
| Autofill the stored resume | **No. Always override.** The account holds one generic resume; the whole point of the pipeline is the per-posting artifact. The recipe MUST clear the autofilled attachment and upload `artifact.resumePdf` explicitly, then verify by filename in the read-back check ([14](14-browser-agent.md)) |
| Autofill custom employer questions | No — those are per-posting and go through the `AnswerBook` |
| API submission | Unchanged: where a documented application endpoint exists, [07](07-apply-pipeline.md) §6 uses it and the browser agent is not involved at all |

The autofilled-resume trap is the single most likely way this system quietly sends a generic resume while reporting a tailored one. Hence the filename check, and hence it being a blocking condition rather than a warning.

## Account registry

`~/.dreamjob/accounts.yaml` mirrors the `SiteAccount` rows for human inspection — the user must be able to answer "what accounts does this thing have, and where" without a SQL client.

```yaml
- domain: acme.wd1.myworkdayjobs.com
  kind: atsTenant           # atsTenant | atsGlobal | careerPage
  platform: workday
  email: user+acme@gmail.com
  emailStrategy: plusTag
  credentialRef: cred_01J8Z...      # keychain handle; no secret here
  createdAt: 2026-07-14
  lastLoginAt: 2026-08-02
  phoneVerified: true
  applications: 3
```

Deleting an entry deletes the keychain item and the browser profile. It does not delete the account at the employer — dreamJob cannot and should not attempt that; the registry links out to each platform's account-deletion page instead.

## Open questions

- Per-tenant Workday accounts mean the user's email alias list grows without bound. Is a catch-all domain effectively a requirement for Workday support rather than an option?
- Should `SiteAccount` creation require the human gate on *every* new account, or once per platform after the user has seen the flow? Every-time is safer and will get tedious around account 30.
- Is there a defensible automated path for TOTP (the user scans the QR into their own authenticator, dreamJob never holds the seed) or does 2FA simply mean `manual-only`?
- Email aliasing gives near-perfect attribution for [16](16-mailbox.md), but a plus-tagged address on a resume looks odd to a human recruiter. Does the alias go on the *account* only, with the plain address on the resume itself?
- Does importing the LinkedIn data export actually beat the existing "point the skills at your PDF" path, or is it a second resume source that has to be reconciled with the first?
