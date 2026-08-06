# 11 — Frontend (Flutter) & design system

**Status: specified.** M3.

The frontend is **Flutter, mobile-first**. One codebase for the swipe deck, the review queue, and the tracker, running on a phone and talking to the Dart backend over the LAN.

**The phone is the entire UX. Everything else is machinery.** Ingestion, matching, the tailoring agent, the browser agent, the credential vault and the mailbox all run on the server and have no interface of their own — the Playwright window in [14](14-browser-agent.md) is not a UI surface, it is a subprocess that happens to be visible. Every decision those subsystems need from a human is rendered in this app, on a phone, over the LAN. If a flow can only be completed by sitting at the server, it is unfinished.

## Platform targets

| Target | Priority | Notes |
| --- | --- | --- |
| Android | **M3, primary** | The build that has to work. Emulator for development, a real device for the demo. |
| iOS | **M3, secondary** | Same code; needs a Mac and a signing profile. Layout is verified here, but Android is the reference. |
| macOS / Windows / Linux desktop | Dev convenience | Faster hot reload and easier debugging than an emulator. Not a shipped target — nothing may work *only* here. |
| Flutter web | Not planned | Adds a CORS and certificate problem to a LAN client for no gain. |

**The phone reaches the server over the LAN**, with a pairing token and pinned TLS — the mechanism, and its security consequences, are in [09](09-compliance.md). Two practical rules follow:

- The app must behave sanely when the server is unreachable: cached deck, queued swipes, an explicit offline banner ([06](06-swipe-ui.md)).
- No LLM call and no PDF rendering ever happens on the phone. Both live on the server, where the API key and `pdftotext` are.

## App architecture

```
lib/
  main.dart
  app/                  # bootstrap, theme, router, pairing flow
  core/
    api/                # client (dio) over the shared models
    models/             # re-exported from dreamjob_shared — NOT redefined here
    theme/              # tokens, ThemeExtensions, motion constants
    cache/              # drift mirror of deck + pending swipes
  features/
    deck/               # swipe deck — cards, gestures, controller
    review/             # review queue, resume diff, approval gate
    submit/             # M5b: submit gate — form screenshot, field table, Submit
    challenges/         # M5a: verification codes, unanswered form questions
    answers/            # M5a: AnswerBook editor (14)
    accounts/           # M5a: site accounts, mailbox connection, revocation (15, 16)
    applications/       # tracker, timeline, follow-ups
    profile/            # profile editor
  shared/
    widgets/            # design-system primitives
    motion/             # reusable transitions and spring curves
test/
  golden/               # card layout goldens, keyed to cardVersion
```

**`core/models/` re-exports `dreamjob_shared`.** The app never declares its own `JobPosting`. That shared package is the whole reason the backend is Dart ([02](02-architecture.md)); redefining a model here throws it away.

### The four backend flows the phone has to surface

Everything from M5 onward is a background subsystem that occasionally needs a human. Each one gets a screen, and none of them may require the server's display.

| Flow | Screen | Constraint it imposes on the app |
| --- | --- | --- |
| **Submit gate** ([14](14-browser-agent.md)) | `submit/` — full-width form screenshot, pinch-zoomable, plus the read-back field table and the attached filename with its hash tick | The screenshot is the artifact being approved, so image quality and zoom are functional requirements, not polish. **Submit** mints the human token; it is never pre-armed and there is no "submit all" |
| **Verification code** ([15](15-accounts-identity.md), [16](16-mailbox.md)) | `challenges/` — the asking domain shown *above* the input, six-digit entry, 5-minute countdown | Time-critical and interruptive. The domain must be visible before the keyboard opens, because "type a code you received into an app" is otherwise a phishing shape |
| **Unanswered form question** ([14](14-browser-agent.md)) | `challenges/` — the question quoted verbatim, free input, "save for future applications" defaulted on | The answer is written back to the `AnswerBook`, so this screen is how that file grows. It must never present a suggested answer |
| **Accounts & connections** ([15](15-accounts-identity.md), [16](16-mailbox.md)) | `accounts/` — employer accounts, the mailbox grant, per-site status, revocation | Read-and-revoke only. **No password is ever displayed, transmitted to the phone, or entered here** ([09](09-compliance.md)) |

**Runs that need a human start only when a human is present.** A registration or submission that can raise a challenge is kicked off from an app session, not by the scheduler — the 5-minute code window is unwinnable otherwise, and it removes any need for a push service. Background work with no human in it (ingestion, matching, tailoring, mailbox sync) stays on the server's own schedule.

**Two additions to the offline rules.** A queued challenge that expires while the phone is unreachable fails cleanly and is retried later; it is never resolved without the user. And the app must render a `needs_attention` application usefully — halt reason, quoted question, last screenshot — because that is the state the user lands in whenever the phone genuinely cannot resolve something.

**Packages** — each verify the maintained version before adopting:

| Concern | Package | Note |
| --- | --- | --- |
| Models | `dreamjob_shared` (`freezed` + `json_serializable`) | Compiled from the same source as the server |
| State | `flutter_riverpod` | Compile-safe, testable |
| Routing | `go_router` | Deck / review / tracker / profile |
| HTTP | `dio` | Interceptors for the bearer token, retry, and offline detection |
| Local cache | `drift` | Same package as the server's store |
| Secure storage | `flutter_secure_storage` | The pairing token — Keychain / Keystore |
| Pairing | `mobile_scanner` | Scans the server's QR code |
| Icons | `iconsax` (see below) | The one item on the reference list directly usable in Flutter |
| Vector assets | `flutter_svg` | Haikei-generated backgrounds |
| Type | `google_fonts` | Whatever pairing Fontjoy lands on |
| Micro-interactions | `flutter_animate` | Keeps animation out of widget build logic |
| Rich motion | `rive` | The Flutter-native answer to Spline/Unicorn-style motion |

**Deck gestures.** Build on `GestureDetector` + `AnimationController` + `SpringSimulation` rather than adopting a card-swiper package wholesale. `appinio_swiper` and `flutter_card_swiper` are worth reading as references, but [06](06-swipe-ui.md) requires undo with compensating events, `dwellMs` instrumentation, on-screen button equivalents for every gesture, and reduced-motion — bending a package to all four is more work than owning ~300 lines.

## Design system

The reference list is almost entirely web, and Flutter cannot consume any of it as code. What it *can* consume is the **decisions**: tokens, scales, curves, and craft standards. So the design system is defined once as tokens and expressed in Flutter, with the references feeding the token values rather than the widget tree.

### Tokens

Defined in `core/theme/` as `ThemeExtension`s so they're reachable off `Theme.of(context)` and swappable for light/dark:

```dart
@immutable
class DreamJobTokens extends ThemeExtension<DreamJobTokens> {
  final DreamJobColors color;      // surface, elevated, text, muted, accent,
                                   // positive (apply), negative (skip), warning
  final DreamJobType type;         // display, title, body, label, mono — one scale
  final DreamJobSpace space;       // 4 / 8 / 12 / 16 / 24 / 32 / 48
  final DreamJobRadius radius;     // card, control, pill
  final DreamJobMotion motion;     // durations + curves, below
  final DreamJobElevation shadow;  // the card stack needs exactly three levels
}
```

Rules:

- **No raw hex, no magic numbers, in any widget.** If a value isn't a token, it's a bug or a missing token.
- **Semantic colours, not literal ones.** `color.positive`, not `color.green` — apply/skip affordances must survive a palette change.
- Meaning never carried by colour alone ([06](06-swipe-ui.md)); every state carries text or shape too.
- One type scale. A card that invents a font size is a card that drifts.
- Touch targets ≥ 48dp. This is a thumb-driven app.

### Motion

Motion is where craft is most visible here — the deck is a swipe interaction, and a laggy or over-eased card feels wrong immediately. The animation references on the list (Motion, Anime.js, animations.dev, emilkowal.ski) are web tooling, but their **principles port directly**, and that's what to take from them.

```dart
class DreamJobMotion {
  final Duration instant   = const Duration(milliseconds: 100); // state flips
  final Duration quick     = const Duration(milliseconds: 180); // press, ripple
  final Duration standard  = const Duration(milliseconds: 260); // card enter/exit
  final Duration deliberate= const Duration(milliseconds: 400); // screen transitions
  // Card physics use a SpringDescription, not a Curve — a swiped card should
  // carry the velocity of the gesture that threw it.
  final SpringDescription cardSpring =
      const SpringDescription(mass: 1, stiffness: 180, damping: 22);
}
```

Standards:

1. **Gesture-driven motion is interruptible and velocity-aware.** A card follows the thumb 1:1 and springs from the release velocity. A card that plays a fixed animation after release feels dead.
2. **Nothing over 400ms** except a deliberate screen transition. Deck throughput is the product metric.
3. **Animate transform and opacity.** Layout-animating a card stack costs frames Flutter shouldn't have to spend.
4. **`MediaQuery.disableAnimations` is honoured everywhere** — durations collapse to zero, springs become cuts. [06](06-swipe-ui.md) requires it.
5. **Budget: a locked 60fps on a mid-range Android phone**, 120fps where the display allows. `RepaintBoundary` around each card; only the top two cards are live widgets, the rest of the stack is a static hint. **Profile on a real device, not the emulator** — emulator frame timings are meaningless.

### Design review

Card layout is covered by **golden tests keyed to `cardVersion`** ([03](03-data-model.md)). A layout change that doesn't bump `cardVersion` fails CI — the M7 training data depends on knowing what the user actually saw.

## The reference list, classified

All 28 links, sorted by what a Flutter codebase can actually do with them. This matters because roughly two-thirds are React and **cannot be imported** — treating the list as a shopping list would waste days.

### A. Usable directly in Flutter

| Resource | Use |
| --- | --- |
| [iconsax.io](https://iconsax.io/) | The icon set. Flutter packages exist on pub.dev (`iconsax`, `iconsax_flutter`) — check which is maintained, and pin it. Sole icon source; mixing icon families is the fastest way to look unfinished. |
| [haikei.app](https://haikei.app/) | Export SVG backgrounds/blobs, render with `flutter_svg`. Good for empty states and the end-of-deck screen. |
| [fontjoy.com](https://fontjoy.com/) | Pick the display/body pairing, then wire it through `google_fonts`. Decide once, record in tokens. |
| [spline.design](https://spline.design/) / [unicorn.studio](https://www.unicorn.studio/) | 3D and interactive motion, but both are WebGL-first. In Flutter they are *asset sources* (rendered video/sprite) or a prompt to build the equivalent in **Rive**, which is the native fit. Do not plan on embedding either — and be sparing: heavy motion on a mid-range phone costs frames the deck needs. |

### B. Agent-facing design skills — usable, framework-agnostic

These four are the "skills" in the request and the most transferable items on the list, because they ship **rules and vocabulary**, not components.

| Resource | Use |
| --- | --- |
| [designmd.ai](https://designmd.ai/) | Design systems packaged as markdown for AI coding tools. Adopt one as the starting point for the token values above, then translate it into `DreamJobTokens`. |
| [tasteskill.dev](https://www.tasteskill.dev/) | Design-system rules + skill files that stop agents from producing generic UI. Install alongside the resume skills in [`skills/`](../skills/). |
| [impeccable.style](https://impeccable.style/#downloads) | "Design vocabulary for agents" — installable as a Claude Code skill (`npx skills add pbakaus/impeccable`), plus a CLI and a Chrome-extension detector. **Caveat:** the detector overlay and CI checks operate on the DOM, so they will not run against Flutter renders. The vocabulary and the skill still apply; the automated detector does not. |
| [namethatui.com](https://namethatui.com/) | Visual dictionary for naming components correctly. Its value is precision in specs and prompts — a scrim named "scrim" gets built right the first time. |

Adopting B is a real decision: these skills carry opinions that can conflict with each other and with the tokens here. Pick **one** as the primary design authority, use the others as review lenses, and record which won in `core/theme/README.md`.

### C. Inspiration and reference only — no code

| Resource | Use |
| --- | --- |
| [mobbin.com](https://mobbin.com/) | Real app screenshots, mobile-first. **The most directly useful item on the list** now that the target is a phone — card decks, onboarding, empty states, permission prompts. |
| [styles.refero.design](https://styles.refero.design/) | Real-world style guides; useful for calibrating type scale and spacing against shipped products. |
| [recent.design](https://recent.design/) | Recent work gallery — trend calibration, not patterns to copy. |
| [emilkowal.ski](https://emilkowal.ski/) | Writing on interaction craft. The best single source for *why* the motion rules above are what they are. |
| [animations.dev](https://animations.dev/) | Animation course (same author). Principles port to Flutter; the code does not. |
| [motion.so](https://motion.so/) | The AI calendar product — a product-design reference for dense daily-decision UI, not a library. |
| [pen.dev](https://www.pen.dev/) | Design-to-code canvas ("design on canvas, land in code"). Web output; useful for exploring layout, not for shipping Flutter. |
| [10x.app](https://www.10x.app/) | AI app builder that emits **SwiftUI** — a mobile-first reference for the on-device build loop, with incompatible output. |
| [framer.com](https://www.framer.com/) | Prototyping and marketing-site tool. Use for a landing page if one is ever needed; not for app UI. |

### D. React/web component libraries — not usable in Flutter

[ui.shadcn.com](https://ui.shadcn.com/) · [chakra-ui.com](https://chakra-ui.com/) · [ui.aceternity.com](https://ui.aceternity.com/) · [cult-ui.com](https://www.cult-ui.com/) · [skiper-ui.com](https://skiper-ui.com/) · [ui.watermelon.sh](https://ui.watermelon.sh/) · [sileo.aaryan.design](https://sileo.aaryan.design/) · [motion.dev](https://motion.dev/) · [animejs.com](https://animejs.com/)

None of these can be imported. They remain useful as **specimens**: shadcn for component API surface and naming, Aceternity/cult/Skiper for motion ideas worth reimplementing, Sileo for toast behaviour (SVG morphing + spring physics — reimplementable with `flutter_animate` and a custom painter), Motion and Anime.js for easing and spring parameter values that transfer numerically to `SpringDescription`.

The trap to avoid: porting a React component's *implementation* into Flutter. Take the interaction, rebuild it with Flutter primitives.

## Open questions

- **Which design authority wins** between DESIGN.md, Taste Skill, and Impeccable when they conflict. Pick before writing tokens, not after.
- **Dark mode only, or both?** A deck app used in evening bursts has a case for dark-first; both doubles the golden-test surface.
- Is a custom `analyzer` lint banning raw colours and durations outside tokens worth building, given Impeccable's detector can't see Flutter output?
- Rive vs a hand-built `CustomPainter` for the card-stack flourishes — Rive adds a runtime and an asset pipeline for what may be three animations.
- Does the app need push notifications ("12 new matches")? It's the obvious mobile affordance and it drags in a push service, which is a new third party for [09](09-compliance.md) to rule on. Note the verification challenges no longer force this: runs that can raise one are user-initiated from a live app session, so an in-app prompt is sufficient.
- Golden tests are specified for the card. Does the submit-gate screen deserve them too? It renders a server-supplied screenshot, so its own layout is simple — but it is the last thing a user sees before an application leaves.
- The submit gate and the deck have opposite tempos: the deck is optimised for a five-minute swipe session, the gate for slowing down and reading. Do they share motion tokens, or does the gate deliberately use the `deliberate` duration everywhere?
