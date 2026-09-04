import Foundation
import SwiftData

/// A user-described recurring pattern, in their own words rather than a
/// rule builder — master prompt § 78: "natural language should create
/// automations." A Routine is always descriptive context the Priority
/// Engine and Life Brief can reference ("you usually leave at 07:45");
/// when `reminderHour`/`reminderMinute` are set, it's *also* a real
/// scheduled action — a repeating local notification at that time
/// (`NotificationScheduler.scheduleDaily`, wired from `RoutinesListView`).
///
/// That's the one trigger type this app can execute honestly without a
/// bigger permission ask: a daily time is enough to schedule a repeating
/// notification. A location-based trigger ("when I get home") would need
/// "Always" location access for background region monitoring — a much
/// more sensitive permission than anything else Aeria asks for — so
/// location-triggered routines stay descriptive-only for now. See
/// docs/ROADMAP.md.
@Model
final class Routine {
    @Attribute(.unique) var id: UUID
    var name: String
    /// What the user said, verbatim where possible: "when I get home after
    /// work" / "every morning around 7".
    var triggerDescription: String
    var associatedMode: LifeMode?
    var actionDescription: String
    var isEnabled: Bool
    /// Non-nil together when this routine is backed by a real daily
    /// notification; nil means descriptive-only.
    var reminderHour: Int?
    var reminderMinute: Int?
    var provenance: Provenance
    var createdAt: Date
    var updatedAt: Date
    var isArchived: Bool

    var hasScheduledReminder: Bool { reminderHour != nil && reminderMinute != nil }
    var notificationIdentifier: String { "routine-\(id.uuidString)" }

    init(
        name: String,
        triggerDescription: String,
        associatedMode: LifeMode? = nil,
        actionDescription: String = "",
        provenance: Provenance = .userProvided,
        createdAt: Date = .now
    ) {
        self.id = UUID()
        self.name = name
        self.triggerDescription = triggerDescription
        self.associatedMode = associatedMode
        self.actionDescription = actionDescription
        self.isEnabled = true
        self.reminderHour = nil
        self.reminderMinute = nil
        self.provenance = provenance
        self.createdAt = createdAt
        self.updatedAt = createdAt
        self.isArchived = false
    }
}
