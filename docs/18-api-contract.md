# 18 — API contract

**Status: specified.** M3 for the HTTP surface, M1 for the core boundary. Blocks both.

There is no shared package. The Flutter app is Dart, the service is Go, the core is Rust, and nothing forces them to agree. This doc is what forces them to agree.

## The rule

**`contract/` is the source of truth. Every type on every boundary is generated from it. A hand-written struct that mirrors a contract type is a defect, not a shortcut.**

```
contract/
  openapi.yaml            # HTTP: app  ↔ server        (OpenAPI 3.1)
  core/
    normalize.json        # subprocess: server ↔ core  (JSON Schema draft 2020-12)
    match.json
    resume.json
  sidecar.json            # loopback HTTP: server ↔ browser sidecar (14)
  CHANGELOG.md
```

| Boundary | Contract | Generated into |
| --- | --- | --- |
| App ↔ server | `openapi.yaml` | Go handler interfaces + types (`oapi-codegen`), Dart client + models (`openapi-generator`) |
| Server ↔ core | `core/*.json` | Go request/response types, Rust `serde` types (`typify`) |
| Server ↔ sidecar | `sidecar.json` | Go types, TypeScript types (`json-schema-to-typescript`) |

Generation runs in `make generate` and in CI. **CI fails if regenerating produces a diff** — that single check is what stops the three languages drifting, and it is the closest thing left to the compile-checked guarantee the Dart design had ([02](02-architecture.md)).

## HTTP conventions

- **Base path `/v1`.** Bumped only on a breaking change; additive fields are not breaking.
- **JSON only.** No HTML, no form encoding, no file uploads from the app — artifacts live on the server and are referenced by id.
- **Every request carries `Authorization: Bearer <token>`.** There is no unauthenticated route, not even health — a 401 must not reveal whether dreamJob is running ([09](09-compliance.md)).
- **Errors are RFC 9457 `application/problem+json`**, with a stable machine-readable `type` slug. The app switches on `type`, never on the human `detail` string.

```json
{ "type": "placeholders_unfilled", "title": "Application has unfilled placeholders",
  "status": 409, "detail": "2 bullets still contain [verify before sending]",
  "instance": "/v1/applications/01J.../approve" }
```

- **Cursor pagination** (`?cursor=&limit=`) everywhere a list can grow. Offsets break under concurrent ingestion.
- **Idempotency by client-generated id** on every write the app can retry. Swipes already mint their own ids ([03](03-data-model.md)); the server treats a re-sent id as a no-op and returns the original result, not a conflict.
- **`ETag` + `If-None-Match` on the deck**, so a phone that reconnects re-syncs cheaply.
- **Timestamps are RFC 3339, UTC, always.** Local time never crosses the wire.
- **Enums are strings**, `snake_case`, and unknown values are a hard error rather than a silent default — the same rule the data model applies to `Unknown` ([03](03-data-model.md)).

## Endpoints

### Pairing and session
| Method | Path | Notes |
| --- | --- | --- |
| `POST` | `/v1/pair` | Exchanges the QR payload for a long-lived token. The **only** route reachable with the pairing secret instead of a bearer token, single-use, expires 60s after the QR is printed |
| `GET` | `/v1/session` | Who am I, server version, contract version, capability flags (`browser`, `mailbox`, `submit`) |

The app reads capability flags rather than assuming: a server without a mailbox grant or a browser sidecar must not render screens for them.

### Profile and answers
| Method | Path | Notes |
| --- | --- | --- |
| `GET`/`PUT` | `/v1/profile` | `PUT` bumps `version` and invalidates `Match` rows; returns the new version |
| `GET`/`PUT` | `/v1/answers` | The `AnswerBook` ([14](14-browser-agent.md)) |
| `POST` | `/v1/answers/keys` | Adds one key with the user's answer, from the unanswered-question prompt |

`PUT /v1/answers` MUST reject any write that sets a `voluntary.*` field to something other than `decline` unless the request carries an explicit `user_initiated: true` — the model has no path to those fields ([09](09-compliance.md)), and this is where that is enforced rather than merely intended.

### Deck and swipes
| Method | Path | Notes |
| --- | --- | --- |
| `GET` | `/v1/deck` | Cards above threshold, sorted, with `Match.reasons`. `ETag`-cached |
| `GET` | `/v1/postings/{id}` | Full posting including `description_html` |
| `POST` | `/v1/swipes` | Batch, idempotent by client id. Accepts a backlog replayed after an offline session |
| `POST` | `/v1/swipes/{id}/undo` | Appends a compensating event; never deletes |

`POST /v1/swipes` takes an **array** because offline replay is the normal case, not the exception. Partial success is reported per item; one rejected swipe never fails the batch.

### Applications and review
| Method | Path | Notes |
| --- | --- | --- |
| `GET` | `/v1/applications` | Filter by status, company, date |
| `GET` | `/v1/applications/{id}` | Includes artifacts, agent runs, and blocking-check results |
| `GET` | `/v1/applications/{id}/artifacts/{kind}` | Streams the rendered PDF or markdown for review |
| `POST` | `/v1/applications/{id}/approve` | Content gate. 409 with a `problem+json` `type` naming the failed check |
| `POST` | `/v1/applications/{id}/retailor` | Re-runs the agent stages |
| `POST` | `/v1/applications/{id}/abandon` | Records the reason as matcher feedback |
| `POST` | `/v1/applications/{id}/outcome` | Manual outcome entry — works with no mailbox connected |

### Submit gate
| Method | Path | Notes |
| --- | --- | --- |
| `GET` | `/v1/applications/{id}/submission` | The filled-form screenshot, the read-back field table, the attached filename and its hash |
| `POST` | `/v1/applications/{id}/submit` | **Mints the human token** and hands it to the sidecar. Single-use, 10-minute expiry, bound to this application |
| `POST` | `/v1/applications/{id}/submit/defer` | "Fix in browser" — parks for a human at the server |

`POST .../submit` is the most security-relevant route in the system. It requires a bearer token, the application to be `approved`, every `FilledField.verified` to be true, and it is rate-limited to the same 5/hour cap as everything else. It is never callable twice for one application.

### Challenges
| Method | Path | Notes |
| --- | --- | --- |
| `GET` | `/v1/challenges/open` | At most one, with domain, kind, and expiry — long-poll with `?wait=30s` |
| `POST` | `/v1/challenges/{id}/answer` | The code. **Never logged, never persisted, never echoed in the response** |
| `POST` | `/v1/challenges/{id}/cancel` | Refuses the challenge and halts the run |

Long-poll rather than push: the challenge only exists inside a session the user started ([11](11-frontend.md)), so the app is already open and there is no push service to add.

### Accounts, sources and mailbox
| Method | Path | Notes |
| --- | --- | --- |
| `GET` | `/v1/accounts` | Site accounts — domain, alias, status. **Never a secret, in any field** |
| `POST` | `/v1/accounts/{id}/revoke` | Deletes the keychain item and the browser profile |
| `POST` | `/v1/accounts/registrations/{id}/approve` | Approves one new employer signup |
| `GET` | `/v1/sources` | Configured boards and their last sync, for the staleness indicator |
| `POST` | `/v1/sources/sync` | Manual "check now" |
| `GET` | `/v1/mailbox` | Connection status and the derived sender allowlist |
| `POST` | `/v1/mailbox/disconnect` | Deletes the token and stored messages together |

**A response body containing a password, an OAuth token, a session cookie, or a verification code is a contract violation.** The OpenAPI document has no schema in which one can appear, and a contract test asserts that no response schema has a property matching `(?i)(password|secret|token|cookie|code)` outside the pairing route.

## The core boundary

`dreamjob-core` is a binary, not a service. Go runs it with a verb, writes JSON to stdin, reads JSON from stdout.

```
dreamjob-core normalize   < {raw, source, now}          > {posting} | {error}
dreamjob-core fingerprint < {posting}                   > {fingerprint}
dreamjob-core match       < {postings[], profile, swipe_history, now} > {matches[]}
dreamjob-core assemble    < {master, bullets_md, keywords} > {resume_doc}
dreamjob-core render      < {resume_doc, format, out}   > {artifact}
dreamjob-core verify      < {artifact, keywords}        > {verdict}
```

Rules:

1. **Every input carries `now`.** The core has no clock ([02](02-architecture.md) invariant 10), so freshness scoring and timestamps are inputs. This is what makes a matcher run reproducible a year later.
2. **Every input carries `contract_version`.** A mismatch is a hard error, not a best-effort parse. Go and the core are separate binaries and can be separately stale.
3. **Batch verbs return per-item results**, each either a value or an error. One malformed posting must not fail a board ([02](02-architecture.md)).
4. **stdout is JSON and nothing else.** Logs go to stderr. A `println!` debugging statement that reaches stdout corrupts the protocol, which is exactly why this is written down.
5. **Exit codes:** `0` success (including per-item errors), `2` bad input, `3` contract mismatch, `101` panic. Go treats `101` as a reproducible bug and keeps the stdin that caused it.
6. **No filesystem access except paths handed to it** in the request, and no network access at all. A core that reads `~/.dreamjob` on its own is a core that can't be tested from a fixture.

## Contract tests

Generated types prove the *shape* matches. These prove the *behaviour* does:

| Test | Where | Catches |
| --- | --- | --- |
| Golden request/response pairs per endpoint, replayed against the real handler | Go | Server drifting from the document |
| The same goldens replayed against the Dart client | Dart | App drifting from the document |
| Round-trip: every example in `openapi.yaml` deserializes, re-serializes, and compares equal | Both | Silent field loss, the classic tri-state bug |
| `git diff --exit-code` after `make generate` | CI | Someone hand-editing generated code |
| No-secret-in-schema scan | CI | A credential field appearing in a response |
| Core fixtures: a directory of `input.json` / `expected.json` pairs | Rust + Go | Core and server disagreeing about the subprocess protocol |

The round-trip test is the one that earns its keep. The most likely failure in this stack is a `bool` that should have been `*bool` in Go silently turning "the posting did not say" into "no" ([03](03-data-model.md)), and a shape-only check will not see it.

## Versioning

- `contract_version` is a single integer for the whole `contract/` directory, bumped in `CHANGELOG.md` with what changed and why.
- **Additive is free.** New optional field, new enum variant that old clients may reject loudly, new endpoint.
- **Breaking requires a `/v2` path or a new verb**, and — since this is a single-user system where the app and server are updated together — a breaking change is usually fine. Say so rather than pretending otherwise; ceremony that protects nobody is waste.
- The app shows a clear "server and app versions disagree" state rather than failing obscurely. Version skew is the normal cost of dropping the shared package, and it needs a visible UI state, not a crash.

## Open questions

- OpenAPI 3.1 with JSON Schema for both boundaries, or gRPC/protobuf for the core boundary? Protobuf would give one IDL and real codegen for three languages; it also means a binary protocol on a stdin pipe you can no longer read with `jq`, which is most of why the subprocess design is pleasant.
- Is `oapi-codegen`'s strict server interface worth it over writing handlers by hand against generated types? Strict mode means the compiler enforces the contract inside the server too — which is the closest thing to getting the old guarantee back.
- Should the sidecar contract really be a third document, or is it internal enough to live as Go types with a TypeScript mirror maintained by hand? It crosses a language boundary, which argues for generating it.
- Long-polling challenges is simple and holds a connection per open challenge. At one challenge system-wide, is that ever a problem worth SSE?
- Does the deck endpoint return `Match.components` (seven floats per card) always, or only on request? The card shows reasons; the components are for the "why" drill-down that most users open rarely.
