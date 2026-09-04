# Roadmap

Phasing follows the master build prompt §§ 81–84. Status reflects this
repository as of the initial scaffold commit.

## MVP (§ 81) — this pass

| Feature | Status |
|---|---|
| Today | ✅ Built — greeting, schedule, Worth Knowing, Aeria observation card |
| Calendar integration | ✅ Built — EventKit, read + create |
| Reminders integration | ✅ Built — EventKit, read + create + complete |
| Life Inbox | ✅ Built — capture bar + filing (Task / Promise / Dismiss) |
| Ask Aeria | ✅ Built — rule-based provider, structured responses, action previews |
| Memory | ✅ Built — `MemoryFact`, `MemoryStore`, "What Aeria Knows" |
| Vault | ✅ Built — scan (VisionKit), OCR extraction, category browsing |
| Universal Search | ✅ Built — on-device semantic search (`NLEmbedding`) |
| Insights | ✅ Built — via Priority Engine + Loose Ends |
| Notifications | 🟡 Scaffolded — `NotificationScheduler` + `InterruptionBudget` exist; not yet wired to a background scheduling trigger |
| Apple-native design | ✅ Built — shared design system with Aeria+ |
| Cloud sync | 🟡 Deliberately deferred — local-only SwiftData; see `PersistenceController.swift` for the CloudKit turn-on steps |
| Privacy Center | ✅ Built |
| Life Brief | ✅ Built — `LifeBriefGenerator` |
| Check my life / Loose Ends | ✅ Built — `LooseEndsScanner` |
| Context-aware prioritization | ✅ Built — `PriorityEngine`, `LifeModeEngine` |
| Smart scheduling | 🟡 Partial — `CalendarContextProvider.freeIntervals` powers "find me a free evening"; no "leave by" travel-time calculation yet (needs MapKit directions) |
| Document extraction | ✅ Built — Vision OCR + heuristic fields, confidence-gated |
| Purchase/warranty memory | ✅ Built — `Asset` model + Vault linkage |

## V1.1 (§ 82) — not started

- Dedicated UI for `Goal`, `Habit`, `Moment` (data models already exist)
- Full Assets browsing experience (beyond warranty tracking inside Vault)
- Voice capture (Watch/iPhone)
- Share Sheet extension
- Widgets (Small/Medium/Large)
- Live Activities (travel countdown)
- Apple Watch app
- Shortcuts / App Intents

## V2 (§ 83) — not started

- Advanced Life Graph exploration UI
- Predictions (§ 28)
- Decision Engine (§ 27)
- Life Simulator (§ 26)
- Promises as a first-class flagged surface beyond Loose Ends (`Commitment`
  model already exists and is scanned)
- Shared household / family permissions
- Natural-language-authored automations (`Routine` model exists as
  descriptive context only — see its doc comment)

## V3 (§ 84) — not started

- Aeria Agent: multi-step planning with approval ("prepare my trip")

## Explicitly rejected (§ 69)

- No "Life Score." Aeria never reduces the user's life to a number.
