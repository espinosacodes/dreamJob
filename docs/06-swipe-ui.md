# 06 — Swipe UI

**Status: specified.** M3. This doc specifies *interaction*; the Flutter implementation, design tokens, and motion system are in [11](11-frontend.md).

One screen. A deck of cards, one job each, swipe right to apply and left to skip. The entire design constraint is that a day's deck must be finishable in about five minutes without opening a single job posting.

## Card anatomy

Everything needed to decide is on the card face. If the user has to flip or open the posting to answer "is this even plausible", the card has failed.

```
┌─────────────────────────────────────────────┐
│  ●●●○○○○○○○○○  4 / 12          ★ STRONG    │  progress + strength
├─────────────────────────────────────────────┤
│                                             │
│  Senior Backend Engineer                    │  title
│  Fathom Analytics                           │  company
│                                             │
│  🌍 Remote · EU timezones (UTC+0 → +3)      │  work mode + location
│  💶 €95,000 – €120,000 · posted             │  comp, with provenance
│  🧰 Go · Kubernetes · Postgres · gRPC       │  stack (want-tags highlighted)
│  📅 Posted 3 days ago                       │  freshness
│                                             │
│  ─────────────────────────────────────────  │
│  • Own the payments ingestion pipeline      │  the three bullets
│  • 5-person platform team, no on-call       │  that actually matter
│  • Series B, 60 people                      │
│  ─────────────────────────────────────────  │
│                                             │
│  Why you're seeing this                     │
│  Go + Kubernetes on your want list ·        │  Match.reasons, top 3
│  Remote in band · Above your comp floor     │
│                                             │
│  ⚠ Title says Remote, body says 3 days      │  warnings, if any
│    in office                                │
│                                             │
│  [ ← Skip ]   [ ↑ Save ]   [ Apply → ]      │
│              ⌄ full description             │
└─────────────────────────────────────────────┘
```

**Field rules**

- **Comp** always shows provenance. A range scraped from prose is labelled `estimated from description`, never shown as posted. No range shows `no range posted`, not a guess.
- **Work mode** shows the resolved value; a `work_mode_conflict` renders as a warning, not a silent choice.
- **Stack** highlights tags from `profile.stack.want` and greys the rest. Max 6 shown, `+N` for the remainder.
- **The three bullets** come from the posting's `requirements[]`, ranked by how much they differentiate this job — scope, team, and constraints beat boilerplate. This is a summarization step and MUST quote the posting rather than paraphrase it.
- **Warnings** are never suppressed to make a card look better.

## Interactions

Touch is the primary input — this is a phone app. The keyboard and mouse columns exist for the desktop dev build and cost almost nothing to keep.

| Input | Touch | Keyboard | Mouse | Effect |
| --- | --- | --- | --- | --- |
| Skip | swipe left | `←` or `J` | drag left / Skip button | `SwipeEvent{left}`, next card |
| Apply | swipe right | `→` or `K` | drag right / Apply button | `SwipeEvent{right}`, queues an Application, next card |
| Save | swipe up | `↑` | Save button | `SwipeEvent{save}`, decide later |
| Expand | tap card | `Space` | click card | full description inline, deck paused |
| Undo | Undo toast | `U` or `⌘Z` | Undo toast | compensating event, card returns |
| Skip with reason | long-press left | `Shift+←` | — | reason picker, then skip |
| Open posting | overflow menu | `O` | — | original posting in the system browser |
| Quit deck | back gesture | `Esc` | — | progress saved, resumable |

**Rules**

- Every action is reachable by a one-handed thumb. Buttons sit in the lower third; nothing load-bearing lives in the top corners.
- Undo stays available for 10 seconds after any swipe, and for the last swipe indefinitely while the deck is open. A misfired right-swipe MUST be recoverable before the agent run starts — the apply queue holds new applications for 10 seconds before processing.
- Nothing is destructive from the deck. Left-swipe hides a posting from future decks; it does not delete data.
- Expanding a card pauses the dwell timer, since `dwell_ms` is meant to measure decision speed, not reading time.
- Skip-with-reason is optional and never blocking. Reasons feed M7 but a deck that demands justification for each skip is a deck nobody finishes.

## Deck lifecycle

1. **Assemble.** On open, request the deck from the local API: all postings with `passed_filters` and `score ≥ threshold`, not previously swiped, sorted by score.
2. **Session.** Progress indicator top-left, always visible — knowing the deck is finite is what makes it finishable.
3. **Interrupt.** Closing mid-deck saves position. Reopening resumes; new postings ingested meanwhile are merged in by score, not appended.
4. **Empty.** Zero cards shows sync status ("Greenhouse synced 2h ago, 0 new matches") — an empty deck must be distinguishable from a broken pipeline, and from a phone that can't reach the server.
   **Offline.** With the server unreachable, the deck runs from cache and swipes queue locally, replaying on reconnect ([02](02-architecture.md)). The app says it is offline; it never silently pretends the deck is current.
5. **Thin.** Fewer than 5 cards offers the labelled 60–45 stretch band ([05](05-matching.md)).
6. **Fat.** More than 40 cards says so and offers to raise the threshold.
7. **Done.** End-of-deck summary: N applied, N skipped, N saved, and what's queued for tailoring, with a link to the review queue.

## Review queue

A second screen, not part of the deck. Applications in `awaiting_review`, each showing:

- The posting, frozen at apply time.
- The tailored resume with changed bullets highlighted. On a phone there is no room for a side-by-side diff, so it renders as a single scrollable column with each changed bullet showing its original inline on tap. The desktop build may use two columns; the phone layout is the one that has to work.
- The cover letter.
- Any `[verify before sending]` placeholders, called out at the top. **An application with unfilled placeholders cannot be approved** — the button is disabled with the reason shown.
- The keyword coverage delta from `resume-recruiter`: what the posting screens for and what the tailored resume now lands.
- Actions: **Approve & submit**, **Edit** (opens the artifacts), **Re-run tailoring**, **Abandon**.

Approval is per application. There is no "approve all" through M6.

## Submit gate (M5b)

Browser submissions get a second screen, after content approval and before the click ([14](14-browser-agent.md)). It answers a different question: *is this form correct*, not *is this resume good*.

- The final screenshot of the filled form, full width, pinch-zoomable. This is the thing being approved.
- A field table: label → the value that is actually in the DOM after read-back, with the `AnswerBook` key it came from. Fields filled by the semantic-map tier are marked; fields filled from a recipe are not, because those are the boring ones.
- The attached filename, and a tick confirming its hash matches the tailored artifact. **This is the check that catches an ATS candidate profile silently substituting its own stored resume** ([15](15-accounts-identity.md)).
- Actions: **Submit**, **Fix in browser** (hands the user the live headed browser), **Abandon**.

Rules: **Submit** is the only control that mints the human token, it is never pre-armed, and there is no "submit all". A run with any unverified field cannot reach this screen at all.

## Interruptions

Two things can now interrupt the user mid-flow. Both are notifications, both name who is asking, and neither is ever silently auto-resolved.

| Prompt | Trigger | Shape |
| --- | --- | --- |
| **Verification code** | An SMS challenge during registration ([15](15-accounts-identity.md)) | "Acme (acme.wd1.myworkdayjobs.com) sent you a code." Six-digit entry, 5-minute countdown, one attempt. The domain is shown *before* the input, because "type a code you received into an app" is otherwise a phishing shape |
| **Unanswered question** | A required form field with no `AnswerBook` key ([14](14-browser-agent.md)) | The question quoted verbatim, an input, and "save this answer for future applications" defaulted on |

Both park the application rather than blocking the deck. The user can keep swiping while a run waits.

## Accessibility and presentation

- Every gesture has an on-screen button equivalent. Swipe is never the only path — a swipe-only deck is unusable for anyone with a motor impairment.
- Meaning is never carried by colour alone — the strong-match star, the warning icon, and want-tag highlighting all carry text or shape.
- Card text respects system font size; the card grows rather than truncating the three bullets.
- Reduced motion is honoured (`MediaQuery.disableAnimations` in Flutter): cards cut instead of animating.
- Light and dark both supported, following the system theme.
- `card_version` is recorded on every `SwipeEvent` so layout changes don't silently corrupt the M7 training data.

## Open questions

- Is `save` a distinct queue or a deferred right-swipe? ([03](03-data-model.md) raises the same question.)
- Should the review queue be a separate screen, or a second pass through the same deck UI ("swipe to approve")? The second is faster and closer to the product metaphor; it is also how you approve something you didn't read.
- Does the deck need a "companies I'd love" pin that floats matching cards to the top regardless of score?
