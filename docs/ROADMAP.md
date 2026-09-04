# Roadmap

Phasing follows the master build prompt §§ 81–84. Status reflects this
repository after the fourth build pass (real app icon/brand mark from
aeriaplus.se; time-based Routine execution; Person↔Promise linking;
scheduling-conflict detection; lightweight promise-phrasing detection in
Life Inbox) — on top of Share Extension, Live Activities, Decision Engine,
and Life Simulator, which were on top of Widgets, Watch, App Intents, full
Life-section UI, smart scheduling, voice capture, and background
notifications before that.

## MVP (§ 81) — complete

Every item in this section is built. See git history / `docs/ARCHITECTURE.md`
for detail on each.

## V1.1 (§ 82) — complete

| Feature | Status |
|---|---|
| Dedicated UI for Goal/Habit/Moment | ✅ Built |
| Full Assets browsing | ✅ Built |
| Voice capture | ✅ Built — iPhone Life Inbox (`VoiceCaptureRecorder`, on-device where the device supports it). Watch-side voice capture is not built. |
| Widgets | ✅ Built — one adaptive widget, small/medium/large |
| Apple Watch app | ✅ Built — read-only "what's next," delivered via WatchConnectivity |
| Shortcuts / App Intents | ✅ Built — Check My Life, Ask Aeria, Add Task, Remember |
| Share Sheet extension | ✅ Built — text/link/image/PDF, queued via `PendingCapture`, drained into Life Inbox; a captured attachment can be filed straight into Vault |
| Live Activities (travel countdown) | ✅ Built — piggybacks on the Widget extension; least-verified piece of this pass, see `Sources/LiveActivity/TravelActivityAttributes.swift` |

## V2 (§ 83)

| Feature | Status |
|---|---|
| Decision Engine (§ 27) | ✅ Built — `DecisionEngine` + `DecisionRecord`, cost comparison with a "too close to call" bar |
| Life Simulator (§ 26) | ✅ Built — `LifeSimulator`, savings-goal and recurring-cost-change projections, always labeled "Projected" |
| Advanced Life Graph exploration UI | 🟡 Partial — the graph is live and used by Moments' task/document linking, but there's no general-purpose graph browser |
| Predictions (§ 28) | 🟡 Partial — `SchedulingConflictScanner` detects genuine calendar-event overlaps and surfaces them on Today; "unusually busy day," "recurring expenses trending up," and similar broader predictions aren't built |
| Shared household / family permissions | ❌ Not built — blocked on enabling CloudKit first (see docs/ARCHITECTURE.md § Persistence & sync); building this on top of a local-only store would mean rebuilding it again once sync is on |
| Natural-language-authored automations | 🟡 Partial — a `Routine` with a daily time now schedules a real repeating notification (`RoutinesListView`, `NotificationScheduler.scheduleDaily`); a location-based trigger like "when I get home" stays descriptive-only, since executing it would need "Always" location access — a meaningfully bigger permission ask than anything else in this app |
| Promise↔Person linking | ✅ Built — `Commitment.toPersonID` (previously set nowhere in the UI) is now wired: `PersonDetailView` shows a person's open promises, `PromisesView` can link/relink one, matching § 72's own "You said you'd send Anna the document" example |
| Promise-phrasing detection | 🟡 Partial — `CommitmentExtractor` highlights the Life Inbox "Promise" button when a capture sounds like a commitment ("I'll…"), but never files it automatically; true extraction *from* free text into a structured `Commitment` isn't built |
| Deeper email/message intelligence (§ 77) | ❌ Not built, and not buildable as originally described — see docs/ARCHITECTURE.md § Share Extension for why passive inbox/message scanning isn't something any third-party iOS app can do, and what Aeria builds instead |

## V3 (§ 84) — not started

- Aeria Agent: multi-step planning with approval ("prepare my trip")

## Explicitly rejected (§ 69)

- No "Life Score." Aeria never reduces the user's life to a number.
