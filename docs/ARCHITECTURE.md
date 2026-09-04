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
   Context/          EventKit / CoreLocation / WeatherKit — live system state
   Intelligence/      PriorityEngine, Ask Aeria's provider, Life Brief, Loose Ends
   Memory/           MemoryFact CRUD — "What Aeria Knows"
   Vault/            Document OCR/extraction, on-disk file storage
   Search/           On-device semantic search index
   Notifications/    Local notifications behind an interruption budget
   DesignSystem/     Palette, type ramp, spacing/motion tokens, shared components
   Features/         One folder per screen — Today, Ask, Life, Vault, Search,
                      Privacy, Onboarding, Settings
   Navigation/       RootTabView (the four-tab shell)
   App/              AeriaApp entry point, AppEnvironment (DI container)
```

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

---

## What's scaffolded but not built

Data models exist for `Goal`, `Habit`, `Moment`, `Asset` beyond basic
warranty tracking — but there's no dedicated UI for Goals/Habits/Moments yet.
Per master prompt § 82–84 these are V1.1/V2 features; building shallow UI for
all of them now would have spread this pass thin instead of making the MVP
slices (Today, Ask Aeria, Life Inbox, Loose Ends, Vault, Privacy Center,
Search) solid. See [`ROADMAP.md`](ROADMAP.md).

No Watch app, no widgets, no Shortcuts/App Intents, no Live Activities — all
V1.1 (§ 82). The module boundaries above (`Context`, `Intelligence`, `Memory`
as separate folders with no UIKit/SwiftUI imports) were kept clean
specifically so a watchOS or widget extension target can import the same
Swift files later without restructuring anything.
