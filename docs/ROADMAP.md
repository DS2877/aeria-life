# Roadmap

Phasing follows the master build prompt §§ 81–84. Status reflects this
repository after the second build pass (Widgets, Watch, App Intents, full
Life-section UI, smart scheduling, voice capture, background notifications).

## MVP (§ 81)

| Feature | Status |
|---|---|
| Today | ✅ Built — greeting, schedule, Worth Knowing, Aeria observation card (now includes "leave by" travel time when it's imminent) |
| Calendar integration | ✅ Built — EventKit, read + create |
| Reminders integration | ✅ Built — EventKit, read + create + complete |
| Life Inbox | ✅ Built — capture bar (text or voice) + filing (Task / Promise / Dismiss) |
| Ask Aeria | ✅ Built — rule-based provider, structured responses, action previews, also reachable via Siri/Shortcuts |
| Memory | ✅ Built — `MemoryFact`, `MemoryStore`, "What Aeria Knows" |
| Vault | ✅ Built — scan (VisionKit), OCR extraction, category browsing, Assets |
| Universal Search | ✅ Built — on-device semantic search (`NLEmbedding`) |
| Insights | ✅ Built — via Priority Engine + Loose Ends |
| Notifications | ✅ Built — `BackgroundRefreshScheduler` (BGTaskScheduler) runs Loose Ends periodically and fires a local notification only when `InterruptionBudget` clears it |
| Apple-native design | ✅ Built — shared design system with Aeria+ |
| Cloud sync | 🟡 Deliberately deferred — local-only SwiftData; see `PersistenceController.swift` for the CloudKit turn-on steps |
| Privacy Center | ✅ Built |
| Life Brief | ✅ Built — `LifeBriefGenerator` |
| Check my life / Loose Ends | ✅ Built — `LooseEndsScanner` |
| Context-aware prioritization | ✅ Built — `PriorityEngine`, `LifeModeEngine` |
| Smart scheduling | ✅ Built — `CalendarContextProvider.freeIntervals` ("find me a free evening") + `TravelTimeProvider` (real MapKit "leave by X") |
| Document extraction | ✅ Built — Vision OCR + heuristic fields, confidence-gated |
| Purchase/warranty memory | ✅ Built — `Asset` model + full Assets browsing screen |

## V1.1 (§ 82)

| Feature | Status |
|---|---|
| Dedicated UI for Goal/Habit/Moment | ✅ Built |
| Full Assets browsing | ✅ Built |
| Voice capture | ✅ Built — iPhone Life Inbox (`VoiceCaptureRecorder`, on-device where the device supports it). Watch-side voice capture is not built. |
| Widgets | ✅ Built — one adaptive widget, small/medium/large |
| Apple Watch app | ✅ Built — read-only "what's next," delivered via WatchConnectivity |
| Shortcuts / App Intents | ✅ Built — Check My Life, Ask Aeria, Add Task, Remember |
| Share Sheet extension | ❌ Not built |
| Live Activities (travel countdown) | ❌ Not built |

## V2 (§ 83) — not started

- Advanced Life Graph exploration UI (the graph itself is live and used by
  Moments' task/document linking — see docs/ARCHITECTURE.md)
- Predictions (§ 28)
- Decision Engine (§ 27)
- Life Simulator (§ 26)
- Shared household / family permissions
- Natural-language-authored automations (`Routine` model exists as
  descriptive context only — see its doc comment)
- Promises are now a first-class screen (§ 72, built this pass) — what's
  still missing is automatic *extraction* of a promise from free text; today
  a `Commitment` has to be created directly (via Life Inbox filing) rather
  than parsed out of a sentence

## V3 (§ 84) — not started

- Aeria Agent: multi-step planning with approval ("prepare my trip")

## Explicitly rejected (§ 69)

- No "Life Score." Aeria never reduces the user's life to a number.
