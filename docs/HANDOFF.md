# Handoff — Aeria Life OS

Dense technical status dump for picking this project back up in Claude Code.
Not written for human readability; written for fast context-loading. Last
updated 2026-10-28, after ~7.5 weeks idle since the last commit (`dab8654`,
2026-09-04). Nothing has changed in the repo since then — this is the exact
state the project was left in.

## Identity / constraints

- Repo: `DS2877/aeria-life`. Local path on the dev box:
  `C:\Users\fismu\OneDrive\Desktop\aeria-life`.
- **Not the same product as "Aeria+"** (tvOS IPTV client, repo `SexyPlayer`,
  different bundle-ID root `com.aeriaplus.appletv` vs this app's
  `com.aeria.life`). Same company/brand only — shared dark-canvas +
  `#3B9EFF` accent design language, nothing else. Never conflate the two
  repos/folders/contexts.
- Dev machine is Windows; this is a SwiftUI/SwiftData iOS+watchOS app that
  **only builds on macOS + Xcode**. Claude authors/edits all Swift and
  `project.yml` here; the user (non-developer) runs `xcodegen generate` +
  Xcode on their Mac and reports back. Code moves machine-to-machine via git
  only (not OneDrive — Xcode + cloud file sync corrupt each other, hence the
  local path above being under OneDrive is a latent risk, not an endorsement).
- **User is not a developer.** Every hand-off must be exact, copy-pasteable
  terminal commands and literal Xcode UI steps ("click the icon at the top of
  the Xcode window that looks like...") — never "rebuild it" shorthand.
- No committed `.xcodeproj`. `xcodegen generate` (reads `project.yml`) must
  be re-run after every `git pull` that adds new files, or Xcode's file list
  goes stale and produces false "Cannot find X in scope" errors. Pure edits
  to existing files don't need it.

## What's built

Full detail in `docs/ARCHITECTURE.md` and `docs/ROADMAP.md` (both current,
read them for the real detail — this section is just the index). Summary:

- **Data layer**: SwiftData, local-only (`cloudKitDatabase: .none`), 17
  `@Model` types. Life Graph modeled as one generic edge table
  (`LifeRelationship(subjectID, subjectType, predicate, objectID, objectType)`)
  rather than native `@Relationship` — deliberate, avoids migrations when
  adding new relationship kinds. Calendar/Reminders are *not* persisted
  (EventKit stays source of truth; read live via `Context/`).
- **Targets** (XcodeGen, `project.yml`): `Aeria` (main iOS app) +
  `AeriaWidgetsExtension` (WidgetKit + ActivityKit Live Activities) +
  `AeriaWatch` (watchOS, read-only "what's next" via WatchConnectivity) +
  `AeriaShareExtension` (share-sheet capture) + `AeriaTests`/`AeriaUITests`.
  App Group `group.com.aeria.life` for cross-target data (not the SwiftData
  store itself — that stays in the main app's sandbox only).
- **MVP + V1.1 (master-prompt §§ 81–82): fully complete** — Today view,
  Life Inbox, Vault (on-device OCR via Vision), Ask Aeria (rule-based NLP
  provider, zero network calls), Search (substring + on-device `NLEmbedding`
  semantic), Settings/Privacy, full People/Places/Goals/Habits/Moments/
  Promises/Assets UI, Shortcuts/App Intents (4 intents), Widgets, Watch app,
  Share Extension, Live Activities (travel countdown), voice capture
  (iPhone only, not Watch), background proactive notifications with an
  interruption budget.
- **V2 (§ 83): partial.** Built: Decision Engine, Life Simulator, scheduling-
  conflict detection, busy-day prediction (vs. own 4-week baseline),
  Promise↔Person linking, promise-phrasing *nudge* (not auto-filing),
  subscription relevance check-in. Not built: shared/household permissions
  (blocked on CloudKit), natural-language automations beyond a daily-time
  `Routine` notification, general-purpose Life Graph browser, deeper
  email/message intelligence (**not buildable** on iOS at all — no
  third-party app can passively read Mail/Messages; Share Extension is the
  real answer to that idea).
- **V3 (§ 84): not started.** Aeria Agent (multi-step planning w/ approval).
- Explicitly rejected by design: no "Life Score."

## THE BLOCKING ISSUE — app does not launch

This is the single thing stopping all further work, and it was never
resolved. As of the last report from the user (message ~2026-09-05): app
**builds successfully** (no compile errors) on both a real device and
Simulator, but **never progresses past the native launch screen** (shows the
Aeria shield logo, then nothing — stuck indefinitely). Reproduces on both
real device and Simulator, which rules out anything provisioning/signing-
specific.

### What's already in place (commit `dab8654`, pushed, never confirmed fixed)

1. `BackgroundRefreshScheduler.register()` (`Sources/Notifications/BackgroundRefreshScheduler.swift`)
   now guards against a real, uncatchable crash: `BGTaskScheduler.register`
   traps immediately if its identifier isn't in Info.plist's
   `BGTaskSchedulerPermittedIdentifiers` — and this runs as literally the
   first line of `AeriaApp.init()`, before any UI. Added an existence check
   that skips registration (rather than crashing) if the identifier is
   missing. (The identifier *is* correctly declared in `project.yml`, so
   this guard is defensive, not a confirmed fix for anything.)
2. `PersistenceController.makeContainer()` — replaced a stray
   `assertionFailure` (which **traps in Debug builds** despite reading like
   a log line — a real, non-obvious Swift gotcha) with `print`, and hardened
   the in-memory-fallback path with proper nested do/catch + a clearly
   labeled `fatalError` as last resort instead of a silent `try!`.
3. Temporary `print()` checkpoints threaded through the entire startup
   chain, in call order: `AeriaApp.init()` → `BackgroundRefreshScheduler.register()`
   → `AppEnvironment.init()` (property init order: `calendarProvider`,
   `reminderProvider`, `locationProvider`, `notificationScheduler` all
   construct *before* the print lines, since Swift stored-property
   initializers run before a class's `init` body) → `PersistenceController.makeContainer()`.
   These are explicitly marked as safe to leave in / remove once launch is
   reliable — still present in every file above.

### What's been ruled out by static review (no Mac access from this session — can't build/run/attach a debugger directly, everything below is code-reading only)

- **Not a missing-privacy-string crash.** All `NS*UsageDescription` keys
  (`Calendars`, `Reminders`, `Location`, `Camera`, `PhotoLibrary`, `FaceID`,
  `Contacts`, `SpeechRecognition`, `Microphone`) are present in `project.yml`
  (lines ~72–80) and match what `Context/` actually uses.
- **Not eager permission access.** `CalendarContextProvider`,
  `ReminderContextProvider`, `LocationContextProvider` only *read* current
  authorization status in `init` (cheap, synchronous, never triggers an OS
  prompt) — actual access requests are deferred to explicit onboarding
  button taps (`OnboardingView`'s `PermissionStepView` steps).
- **Not a main-thread deadlock.** No `DispatchSemaphore`, `.wait()`,
  `DispatchQueue.main.sync`, or similar blocking pattern exists anywhere in
  `Sources/`.
- **Not a broken onboarding flow.** `OnboardingView.welcomeStep`'s
  "Continue" button and `advance()` state transition are straightforward
  SwiftUI `@State`, nothing exotic.
- **Not a touch-blocking overlay.** `AppThemeBackground` (`DesignSystem/Components/Surfaces.swift`)
  only applies `.background()` (sits behind content, can't intercept taps),
  `.foregroundStyle`, `.tint`, `.preferredColorScheme`.
- **Not a missing asset reference.** `AeriaMark.imageset` and
  `LaunchBackground.colorset` both exist in `Resources/Assets.xcassets`.
- **Not eager WatchConnectivity activation.** `PhoneConnectivityBridge.shared`
  is lazily constructed only when `TodayViewModel` first calls `.send()` —
  well after onboarding, not at app launch.

### What's still unknown

No root cause identified. Every static-review candidate came up clean. The
**only remaining way to make progress is runtime evidence from the user's
Mac**, specifically one of:

1. The actual text printed to Xcode's console (bottom debug panel) up to the
   point it hangs — the print-checkpoint chain above was built exactly so
   the last line reached pinpoints where execution actually stops.
2. A screenshot of Xcode after clicking the pause icon in the running app's
   debug toolbar while it's hung — shows the live stack trace / exact
   line of code executing.

**Neither has ever been obtained.** The user's replies so far ("still stuck
on the first pic with the shield", "no pause button") did not confirm
whether `dab8654` was even pulled and clean-built, and did not include
console text. This is the conversation's actual bottleneck — not a missing
idea, a missing data point. Next Claude Code session on this project should
treat getting that console output/screenshot as the literal first priority
before touching anything else, and should re-send dead-simple, step-by-step
instructions for finding Xcode's Debug Area / pause button, since that
instruction already failed to land once plainly worded.

One hypothesis *not yet ruled out* (worth checking first if/when console
output arrives and shows the chain completing fully, i.e. the hang is
*after* `PersistenceController.makeContainer()` succeeds): something in
first SwiftUI body evaluation of `RootTabView` or `OnboardingView` — e.g. a
`@Query` over the SwiftData container triggering an expensive/blocking
migration-like operation, or a view that's actually rendering fine but whose
"shield" image is visually indistinguishable from the native launch screen
(`OnboardingView.welcomeStep` shows the *same* `AeriaMark` image centered
the same way `UILaunchScreen` does) — meaning the user might already be
looking at a *perfectly rendered, interactive* OnboardingView welcome screen
and just not realize tapping "Continue" would work, because visually it
looks identical to "still the launch screen." This is speculative and
unverified, but cheap to ask the user to test directly: "while it looks
stuck, tap the middle of the screen where a Continue button would be."

## Process notes for continuing work

- Standing instruction: always give the user exact terminal commands /
  Xcode click-paths, never assume dev fluency.
- `git status`'s "up to date with origin/main" only reflects the last
  *fetched* remote ref, not a live check — don't trust it without an
  explicit `git fetch` first if staleness matters.
- AppIntents `AppShortcut` phrases can't embed free-text `String`
  `@Parameter`s inline (only `AppEntity`/`AppEnum`) — already hit and fixed
  once in `AeriaShortcutsProvider.swift`; don't reintroduce it.
- `assertionFailure` is not a log statement — it traps in Debug builds.
  Already caused one real crash here; grep for any other stray use before
  assuming a `print`-shaped comment is accurate.
- Brand mark source: `aeriaplus.se` (`vpn-xOZYPzbL.jpg`, 1200×1200). App
  icon variants must stay fully opaque (no alpha — Apple App Store
  validation rejects icons with an alpha channel, even fully-opaque pixels);
  in-app `AeriaMark` usage must be transparent — these were already
  generated correctly once (luminance→alpha conversion done via PowerShell/
  GDI+ on the Windows box, since no Mac/ImageMagick/Python was available
  here); don't regenerate from the opaque App Store source by mistake.

## Once launch is actually fixed and confirmed

1. Remove every "TEMPORARY diagnostic" `print()` left in `AeriaApp.swift`,
   `AppEnvironment.swift`, `PersistenceController.swift`,
   `BackgroundRefreshScheduler.swift` (all four are explicitly commented as
   safe-to-remove-once-reliable).
2. Resume the V2 roadmap gaps in priority order suggested by `docs/ROADMAP.md`:
   CloudKit sync (unblocks shared/household permissions — the biggest single
   deferred feature), then natural-language automation triggers beyond
   daily-time `Routine`s, then a general Life Graph browser UI.
3. Re-evaluate `FoundationModelsIntelligenceProvider`
   (`Intelligence/FoundationModelsIntelligenceProvider.swift`) — written
   against an API surface that couldn't be verified against a real compiler
   from this (Windows) session; it's not wired into `AppEnvironment` by
   default for exactly that reason. First real Mac build is the first
   chance to confirm whether it actually compiles.
4. Live Activities (`Sources/LiveActivity/`) were flagged as the
   least-verified piece of the whole V1.1 pass (ActivityKit's API shifted
   between iOS versions) — worth a deliberate test pass once the app
   launches at all.
