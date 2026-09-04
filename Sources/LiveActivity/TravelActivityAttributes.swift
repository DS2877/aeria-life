import ActivityKit
import Foundation

/// Master prompt § 41 Live Activities: a travel countdown on the Lock
/// Screen / Dynamic Island — only ever started for the same imminent,
/// real travel-time window Today's Aeria card already shows (§ 20, § 29),
/// never speculatively (§ 41: "never use Live Activities as advertising").
///
/// Shared between the main app (starts/updates/ends the Activity, see
/// `Sources/App/TravelActivityCoordinator.swift`) and the Widget extension
/// (renders it, see `TravelLiveActivityWidget.swift`) — lives in its own
/// `Sources/LiveActivity` folder rather than `Sources/Shared` because
/// ActivityKit isn't available on watchOS, which also compiles
/// `Sources/Shared`. See project.yml for exactly which targets include this
/// folder.
///
/// ActivityKit's exact API shifted between iOS 16.1 and 16.2 (the
/// `ActivityContent` wrapper was added in 16.2). This code targets the
/// current (16.2+) shape, safely within Aeria's 17.0 floor — but Live
/// Activities was the one part of this pass with the least certainty
/// behind it. If `TravelActivityCoordinator.swift` or
/// `TravelLiveActivityWidget.swift` fail to build, that's isolated to those
/// two files plus this one; nothing else depends on them.
struct TravelActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var minutesRemaining: Int
        var leaveByDate: Date
    }

    var eventTitle: String
}
