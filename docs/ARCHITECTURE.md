# Architecture

## Guiding principle

Aeria is a Life OS, not a database browser. Every layer below the UI exists so
that "what matters today" can be computed cheaply and shown calmly — the UI
never touches EventKit, SwiftData, or Vision directly; it goes through a small
number of typed services (see the module map below).

Zero administration is the product bet: the user supplies intent, Aeria
supplies structure. Concretely, that means most screens read from a handful
of pure functions (`PriorityEngine`, `LooseEndsScanner`, `LifeModeEngine`)
rather than bespoke per-screen logic, so "what's worth showing" stays
consistent everywhere it's asked.

---

## Module map

```
 Sources/
   Models/          SwiftData @Model entities — the Life Graph nodes
   Persistence/      ModelContainer setup (local-only for now)
   Context/          EventKit / CoreLocation / WeatherKit / MapKit / Speech — live system state
   Intelligence/      PriorityEngine, Ask Aeria's provider, Life Brief, Loose Ends
   Memory/           MemoryFact CRUD — "What Aeria Knows"
   Vault/            Document OCR/extraction, on-disk file storage
   Search/           On-device semantic search index
   Notifications/    Local notifications, interruption budget, background refresh
   DesignSystem/     Palette, type ramp, spacing/motion tokens, shared components
   Features/         One folder per screen — Today, Ask, Life, Vault, Search,
                      Privacy, Onboarding, Settings
   Navigation/       RootTabView (the four-tab shell)
   App/              AeriaApp entry point, AppEnvironment (DI container), App Intents
   Shared/           TodaySnapshot, PendingCapture — shared with Widgets/Watch/Share
   Widgets/          AeriaWidgetsExtension target (WidgetKit)
   LiveActivity/     Shared between Aeria and AeriaWidgetsExtension (ActivityKit)
   Watch/            AeriaWatch target (watchOS)
   ShareExtension/   AeriaShareExtension target
```

`Shared/`, `LiveActivity/`, and a handful of `DesignSystem` token files are
the *only* sources compiled into more than one target — see `project.yml`'s
per-target `sources` lists for exactly which files go where, and the
comment on the `Aeria` target explaining why `Widgets/`, `Watch/`, and
`ShareExtension/` are explicitly excluded from its own source list (the
first two have their own `@main`; all three belong to exactly one
extension). `LiveActivity/` isn't in `Sources/Shared` because ActivityKit
isn't available on watchOS, which also compiles `Sources/Shared`.

Every feature view takes its dependencies from `AppEnvironment`
(`@EnvironmentObject`) and its own SwiftData `@Query`s — there's no service
locator, no singleton reached for at random; what a view depends on is
visible in its property list.

---

## The Life Graph

Master prompt § 4 describes entities connected by relationships
("car → hasInsurance → policy"). Rather than modelling that with SwiftData's
native `@Relationship` (which requires typed inverse relationships declared
on both sides — brittle to extend, and every new connection type needs a
schema migration), the graph is one generic edge table:

```swift
LifeRelationship(subjectID, subjectType, predicate, objectID, objectType)
```

`predicate` is a closed vocabulary (`owns`, `expiresOn`, `conflictsWith`, …,
see `LifeRelationshipKind`). Entities themselves — `Person`, `Asset`,
`DocumentRecord`, etc. — stay simple, standalone SwiftData models with no
knowledge of the graph. This is the one deliberate divergence from "use
SwiftData relationships" you might expect; it trades a bit of query
convenience for a schema that can grow without migrations.

**Calendar events and reminders are not persisted here at all.** EventKit is
already the durable, synced store Apple provides — duplicating it into
SwiftData would mean two sources of truth that can drift. `CalendarEvent` and
`LifeReminder` (in `Context/`) are lightweight, non-persisted structs read
live from EventKit each time they're needed. `TaskItem` exists only for
things that start life *inside* Aeria (a Life Inbox capture) before the user
decides whether to promote it into a real Reminder.

Every fact carries **provenance** (`Provenance`: user-provided / system data
/ imported / AI inference / AI suggestion) and, where relevant, a
**confidence** (`ConfidenceLevel`: confirmed / high / low) via
`FactAttribution`. The UI's `ConfidenceBadge` and hedge-language rules read
directly off these — see master prompt § 55–57.

---

## Context Engine

```
 EventKit  ──►  CalendarContextProvider / ReminderContextProvider  ──►  CalendarEvent / LifeReminder
 CoreLocation ──►  LocationContextProvider  ──►  nearestKnownPlace(among:)
 WeatherKit (opt-in) ──►  WeatherContextProviding  ──►  WeatherSnapshot
                                    │
                                    ▼
                          LifeModeEngine.inferMode(...)  ──►  LifeMode
```

`LifeModeEngine` is a pure function (time + today's events + nearest known
place + optional manual override → `LifeMode`) — see
`Context/LifeModeEngine.swift` and its tests. Manual override always wins;
Aeria never traps the user in an inferred mode (master prompt § 14).

**WeatherKit is not wired up by default.** `AppEnvironment` binds
`UnavailableWeatherProvider`, which returns `nil` rather than fabricating a
forecast — Today simply omits the weather chip. To turn it on: add the
WeatherKit capability in Xcode (target *Aeria* → Signing & Capabilities) and
switch the binding in `AppEnvironment.init` to `WeatherKitProvider()`
(`Context/WeatherContextProvider.swift`). This wasn't wired up by default so
the very first build doesn't need any Apple Developer portal configuration.

`TravelTimeProvider` (master prompt § 20, § 29 — "leave by X") geocodes the
next event's location string with `CLGeocoder`, then asks `MKDirections` for
a driving-time estimate, adding a fixed buffer on top. `TodayViewModel`
only computes this for a same-day, non-all-day next event, and only shows it
on Today once the leave-by time is within 90 minutes — see
`TodayView.aeriaObservation`. Any failure (no location fix, ungeocodable
address, no route) just yields `nil`; this is additive to Today, never a
dependency of it.

`VoiceCaptureRecorder` (`Context/VoiceCaptureRecorder.swift`, master prompt
§ 75) wraps the standard `SFSpeechRecognizer` + `AVAudioEngine` tap pattern,
requesting on-device recognition when the device supports it. Wired into the
Life Inbox capture bar's mic button (`LifeView`) — live transcript fills the
same text field a typed capture would, so it goes through identical review
before being saved.

`CommitmentExtractor` and `SchedulingConflictScanner` are two more narrow,
pure-function additions. The first is a *nudge, not an auto-filer* —
Life Inbox highlights the "Promise" filing button when a capture's phrasing
sounds like a commitment ("I'll…", "I promise to…"), but never files it
without a tap (master prompt § 9 asks Aeria to classify intent; it doesn't
ask Aeria to stop asking). The second finds genuine time overlaps between
two calendar events and surfaces them on Today with the same urgency as an
imminent "leave by" — see `TodayView.aeriaObservation`'s ordering.

`Routine` (master prompt § 78) is descriptive context by default, but when
it carries a daily time it becomes a real, repeating local notification via
`NotificationScheduler.scheduleDaily` — the one automation trigger this app
executes without asking for anything beyond the notification permission it
already needs elsewhere. A location-based trigger ("when I get home") would
need "Always" location access for background region monitoring, a
meaningfully bigger and more sensitive ask than anything else in this app,
so those stay descriptive-only; see the doc comment on `Routine` itself.

---

## Intelligence

`PriorityEngine` (master prompt § 7) is a pure, deterministic scorer —
urgency (due-date proximity) + base importance + user pin + location
relevance, dampened for low-confidence items, with a `surfaceThreshold` below
which nothing is shown at all. "Nothing important needs your attention right
now" is an intended output, not a fallback (§ 7, § 68 "One Thing").

`AeriaIntelligenceProviding` is the swappable backend for Ask Aeria:

- **`RuleBasedIntelligenceProvider`** (the default) — deterministic keyword +
  `NSDataDetector` date extraction. No network call, no setup, covers every
  example interaction in master prompt § 8.
- **`FoundationModelsIntelligenceProvider`** (opt-in, `Intelligence/FoundationModelsIntelligenceProvider.swift`)
  — Apple's on-device Foundation Models framework (iOS 26+), for genuinely
  open-ended phrasing. **Not wired up by default** — this framework was very
  new when this code was written and its exact API surface couldn't be
  verified against a compiler here. If it fails to build, delete the file;
  `RuleBasedIntelligenceProvider` is fully sufficient on its own. To try it:
  switch the binding in `AppEnvironment.init` to `HybridIntelligenceProvider()`.

`LooseEndsScanner` (master prompt § 11, "Check my life") and
`LifeBriefGenerator` (§ 6, § 12) are both pure functions over already-fetched
records — no fetching of their own, which is what makes them trivially unit
testable (see `Tests/AeriaTests`).

---

## Decision Engine & Life Simulator

Two more pure-function additions alongside `PriorityEngine`:

- **`DecisionEngine`** (master prompt § 27 "Help me decide"): compares
  `DecisionOption`s (upfront + monthly cost, pros/cons — stored as a
  `Codable` array on the persisted `DecisionRecord`, since options only
  ever make sense in the context of one decision) and recommends the
  cheaper one over a user-set horizon, *unless* the gap is under 5%, in
  which case it says so explicitly ("too close to call") rather than
  implying false confidence.
- **`LifeSimulator`** (master prompt § 26): "what if I save X/month"
  and "what if I add/remove this recurring cost" projections. Everything
  it returns is labeled "Projected" in the UI (`LifeSimulatorView`) —
  master prompt § 26 requires distinguishing known from projected, and
  this is never persisted, since a "what if" is meant to be re-run, not
  kept as a record (unlike a `DecisionRecord`, which is a real comparison
  worth revisiting).

---

## Vault & document extraction

Document binaries (scanned images) live in `Application Support/Vault/` via
`VaultStorage`, **not** as SwiftData attribute data — keeping blobs out of
the store keeps queries fast and (once CloudKit is enabled) keeps sync
payloads small.

`DocumentExtractor` runs on-device OCR (`Vision`'s `VNRecognizeTextRequest`)
then heuristic field extraction (date detector, currency regex, category
keywords). Confidence is literally "how many independent signals agreed" —
transparent by construction, not a black box. Anything below the confidence
bar is shown to the user for confirmation before being treated as fact
(`DocumentReviewSheet`, master prompt § 15, § 55).

---

## Search

`LifeSearchIndex` blends plain substring matching with on-device sentence
embeddings from `NaturalLanguage`'s `NLEmbedding` — genuinely "semantic, not
merely keyword-based" (master prompt § 22) without a network call or a
model download. Any type can opt in by conforming to `SearchableRecord`
(see `Search/SearchableRecord+Models.swift`).

---

## Widgets & Watch

Neither surface talks to SwiftData or EventKit directly — both are pure
renderers of a `TodaySnapshot` (`Shared/TodaySnapshot.swift`, a small
`Codable` struct) that `TodayViewModel.publishSnapshot(...)` writes after
every Today refresh. This keeps "what's worth showing" defined in exactly
one place; a widget can never show something Today itself wouldn't.

The two surfaces get the snapshot two different ways, deliberately:

- **Widget** (`AeriaWidgetsExtension`): reads it from a shared App Group
  (`group.com.aeria.life`) `UserDefaults` suite (`SharedStorage`). This is
  the standard, low-risk pattern for a widget that doesn't need live
  queries — no shared SwiftData container, no cross-process store access.
- **Watch** (`AeriaWatch`): receives it over `WatchConnectivity`
  (`PhoneConnectivityBridge` on the phone, `WatchConnectivityReceiver` on
  the watch), via `updateApplicationContext` — fire-and-forget, "latest
  wins," no reachability requirement. `WCSession` is a poor fit for an
  extension's transient lifecycle, which is why the widget doesn't use this
  same path.

Both new targets needed the `Aeria` target's own `- path: Sources` entry to
explicitly `exclude` `Widgets/**` and `Watch/**` — each has its own `@main`,
and without the exclusion the app target would try to compile three entry
points into one module. See the comment in `project.yml`.

**Live Activities** (master prompt § 41) piggyback on the same `Widgets`
extension — that's how ActivityKit works, a Live Activity is declared as a
`Widget` (`TravelLiveActivityWidget`) inside the same `WidgetBundle` as the
home-screen widget. `TravelActivityCoordinator` (main app only) starts,
updates, and ends the activity using the exact same `TravelPlan` and
90-minute imminence window Today's Aeria card already uses
(`TodayView.aeriaObservation`) — a Live Activity never shows something the
app itself wasn't already about to lead with. This was the single piece of
this pass with the least certainty behind it (ActivityKit's API shifted
between iOS 16.1 and 16.2); see the comment atop
`Sources/LiveActivity/TravelActivityAttributes.swift` for the isolation
story if it doesn't build.

---

## Share Extension

`AeriaShareExtension` (master prompt § 76) accepts text, a link, an image,
or a PDF from any app's share sheet. This is also the practical answer to
§ 77 "email/message intelligence": **no third-party iOS app can passively
read your Mail or Messages** — Apple doesn't expose that API to anyone, for
privacy reasons that apply across the whole platform, not just Aeria.
Sharing a message or email *into* Aeria yourself is the version of that
idea that's actually buildable, and it's what this extension is for.

Like the Widget, the extension never touches the main app's SwiftData store
directly — it runs in its own sandboxed process and can't reach it. Instead
it drops a `PendingCapture` (text + optional attachment file) into the App
Group's shared container (`Sources/Shared/PendingCapture.swift`), which
`PendingCaptureImporter` drains into a real `NoteItem` the next time the
main app launches or comes to the foreground (`AeriaApp`'s `.task` and
`scenePhase` handling). From there it's an ordinary Life Inbox item — Life
already lets you file a captured item as a Task or Promise; sharing adds a
"Vault" filing option when the capture carries an attachment, turning it
into a `DocumentRecord` (§ 76's own example: "This looks like a warranty
document... Save to Vault?").

`NSItemProvider.loadItem` is used via its completion-handler form, wrapped
in a continuation, rather than a newer async overload — the same
risk-reduction call made throughout this codebase wherever an exact,
unverifiable API surface was in question.

---

## App Intents / Shortcuts

`Sources/App/AppIntents/` (master prompt § 42–43) — four intents (Add Task,
Remember, Check My Life, Ask Aeria) run in-process against
`PersistenceController.shared`, a container reused by both the SwiftUI app
and any intent invocation, so something created via Siri shows up in the app
immediately. No separate Intents Extension target: these intents execute in
the app's own process (launched in the background if needed), which is why
sharing the container is enough — there's no second process to keep in sync.

`AskAeriaIntent` only populates calendar context if `EKEventStore`
authorization is already `.fullAccess` — otherwise it leaves calendar-derived
fields empty rather than let the rule-based provider's "nothing on your
calendar" phrasing imply "I checked" when it didn't (master prompt § 57).

---

## Proactive notifications

`BackgroundRefreshScheduler` (master prompt § 29) registers a
`BGAppRefreshTask` at app launch (`AeriaApp.init()`) and reschedules itself
every time the app backgrounds. Each run re-runs `LooseEndsScanner` and, only
if `InterruptionDecision.shouldNotify` clears the budget (max/day, minimum
spacing since the last one), fires a single local notification. There's no
path in the app that sends a notification without going through this
decision — see `Notifications/InterruptionBudget.swift`.

Background tasks essentially never fire on demand in the Simulator; test on
a real device, or trigger it manually via LLDB while paused at a breakpoint
after `BGTaskScheduler.shared.register(...)` has run:

```
e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.aeria.life.refresh"]
```

---

## Persistence & sync

Local-only SwiftData (`cloudKitDatabase: .none`) — see
`Persistence/PersistenceController.swift` for exactly what turning on
CloudKit sync later requires. This was a deliberate choice, not a
placeholder: master prompt § 61 requires the app work fully offline, and
shipping local-first means the first build a person runs on their Mac just
works, with no iCloud container or paid-account capability to configure
first.

---

## Design language

Shared with Aeria+ (the tvOS product) — same dark canvas, same accent blue
(`#3B9EFF`), so the two products read as one company (master prompt § 45).
Tokens live in `Sources/DesignSystem/`:

- `Palette.swift` — colour tokens
- `Typography.swift` — the `AeriaFont` type ramp (system/Dynamic Type based)
- `Metrics.swift` — spacing, corner radius, and the `Motion` animation curves
- `Components/` — `SurfaceCard`, `GlassPanel`, `InsightRow`, `ConfidenceBadge`,
  `ActionPreviewCard`, button styles, empty states

Aeria is dark-only by product decision (`AppThemeBackground` forces
`.preferredColorScheme(.dark)`) rather than an `Info.plist` override, so a
future settings toggle can offer light mode without touching Info.plist.

**The app icon is the real Aeria mark** — the glass shield built from a
connected node mesh, pulled directly from aeriaplus.se (`vpn-xOZYPzbL.jpg`,
1200×1200) and re-rendered at 1024×1024 with the alpha channel stripped
(Apple's App Store validation rejects icons carrying one, even fully
opaque — `Resources/Assets.xcassets/AppIcon.appiconset`). The same source
backs the watchOS app icon (its own catalog, `Resources/WatchAssets.xcassets`
— kept separate from the iOS catalog rather than sharing one across
platforms) and an in-app `AeriaMark` image, used once, deliberately, for
the onboarding welcome screen's first impression rather than scattered
through small inline icons — the Ask Aeria tab and entry point still use
the plain `sparkle` SF Symbol, which is the "subtle mark" master prompt § 8
actually asks for at that scale.

---

## What's not built

Predictions, shared/household permissions, and natural-language automations
(§ 83) aren't built — `Routine` exists only as descriptive context an
automation engine could read later, not something that executes anything
yet. Deeper email/message intelligence (§ 77) isn't built *and can't be* on
iOS as a passive background feature — see § Share Extension above for why,
and for the buildable version of that idea. The Agent (§ 84) isn't built.
See [`ROADMAP.md`](ROADMAP.md) for the full status table.
