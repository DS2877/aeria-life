import Foundation

/// A tiny, serializable summary of "what matters right now." The main app
/// writes this after every Today refresh; the Widget extension and the
/// Watch app only ever read it. Neither of those processes touches
/// SwiftData or EventKit directly — that keeps them trivial, keeps exactly
/// one place (TodayView/TodayViewModel) responsible for "what's worth
/// showing" (master prompt § 7), and means a widget can never show
/// something Today itself wouldn't.
///
/// This file is compiled into three targets (Aeria, AeriaWidgets,
/// AeriaWatch — see project.yml) via a shared `Sources/Shared` source path,
/// not a framework. Keep it dependency-free (Foundation only) so it builds
/// identically everywhere.
struct TodaySnapshot: Codable, Equatable {
    struct EventSummary: Codable, Equatable, Identifiable {
        var id: String
        var title: String
        var startDate: Date
        var isAllDay: Bool
    }

    struct Insight: Codable, Equatable, Identifiable {
        var id: String
        var title: String
    }

    var generatedAt: Date
    var greeting: String
    var nextEvents: [EventSummary]
    var insights: [Insight]
    var aeriaHeadline: String
    var openLooseEndCount: Int

    static let empty = TodaySnapshot(
        generatedAt: .distantPast,
        greeting: "Good day",
        nextEvents: [],
        insights: [],
        aeriaHeadline: "Open Aeria to get started.",
        openLooseEndCount: 0
    )
}

/// Shared App Group storage. `appGroupID` must match the App Group
/// entitlement on every target that uses this (see project.yml → each
/// target's `entitlements`). Falls back to `.standard` UserDefaults if the
/// group isn't configured yet, so a widget added before the entitlement is
/// wired up degrades to empty state instead of crashing.
enum SharedStorage {
    static let appGroupID = "group.com.aeria.life"

    static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    private static let snapshotKey = "aeria.todaySnapshot"

    static func writeSnapshot(_ snapshot: TodaySnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: snapshotKey)
    }

    static func readSnapshot() -> TodaySnapshot {
        guard let data = defaults.data(forKey: snapshotKey),
              let snapshot = try? JSONDecoder().decode(TodaySnapshot.self, from: data) else {
            return .empty
        }
        return snapshot
    }

    /// The on-disk App Group container — used only for file-based handoff
    /// (see `PendingCaptureQueue`), never as the SwiftData store's location.
    /// Aeria deliberately keeps the real database in the main app's private
    /// sandbox (see PersistenceController's header comment); the Share
    /// Extension can't reach that directly, so it drops captures here for
    /// the main app to import instead of writing to SwiftData itself.
    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
    }
}
