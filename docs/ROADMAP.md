# Roadmap

Phasing follows the master build prompt §§ 81–84. Status reflects this
repository after the third build pass (Share Extension, Live Activities,
Decision Engine, Life Simulator — on top of Widgets, Watch, App Intents,
full Life-section UI, smart scheduling, voice capture, and background
notifications from the two passes before it).

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
| Predictions (§ 28) | ❌ Not built |
| Shared household / family permissions | ❌ Not built |
| Natural-language-authored automations | ❌ Not built — `Routine` exists only as descriptive context, doesn't execute anything |
| Promise extraction from free text | ❌ Not built — Promises (§ 72) is a real screen now, but a `Commitment` still has to be created directly (Life Inbox filing) rather than parsed out of a sentence like "I'll call you Tuesday" |
| Deeper email/message intelligence (§ 77) | ❌ Not built, and not buildable as originally described — see docs/ARCHITECTURE.md § Share Extension for why passive inbox/message scanning isn't something any third-party iOS app can do, and what Aeria builds instead |

## V3 (§ 84) — not started

- Aeria Agent: multi-step planning with approval ("prepare my trip")

## Explicitly rejected (§ 69)

- No "Life Score." Aeria never reduces the user's life to a number.
