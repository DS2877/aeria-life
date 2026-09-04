import Foundation
import SwiftData

/// A user-described recurring pattern, in their own words rather than a
/// rule builder — master prompt § 78: "natural language should create
/// automations." In the MVP, a Routine is descriptive context that the
/// Priority Engine and Life Brief can reference ("you usually leave at
/// 07:45"); it does not yet execute anything on its own — see
/// docs/ROADMAP.md for the V2 automation engine this sets up.
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
    var provenance: Provenance
    var createdAt: Date
    var updatedAt: Date
    var isArchived: Bool

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
        self.provenance = provenance
        self.createdAt = createdAt
        self.updatedAt = createdAt
        self.isArchived = false
    }
}
