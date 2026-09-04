import Foundation
import SwiftData

/// Master prompt § 10: memory must distinguish explicit instruction from
/// inference from ambient context from plain system fact. "What Aeria
/// Knows" (PrivacyCenter) groups and explains itself by this, not by a
/// single opaque "memory" bucket.
enum MemoryKind: String, Codable, CaseIterable, Hashable {
    /// The user directly told Aeria to remember this ("Remember that I
    /// prefer morning flights"). Never silently overwritten by inference.
    case explicitPreference
    /// Aeria noticed a pattern and is holding it loosely — must stay labeled
    /// as inferred everywhere it's used, and is the first thing pruned if
    /// it stops being useful.
    case inferredPreference
    /// Short-lived context relevant to what's happening right now (a trip
    /// this week, a project deadline) — expected to age out.
    case temporaryContext
    /// A fact mirrored from a system source (home address from an EventKit
    /// location pattern, etc.) rather than something Aeria "decided."
    case systemFact

    var displayName: String {
        switch self {
        case .explicitPreference: return "You told Aeria"
        case .inferredPreference: return "Aeria noticed"
        case .temporaryContext: return "Currently relevant"
        case .systemFact: return "From your device"
        }
    }
}

/// One remembered fact. This *is* the memory system's storage — "What Aeria
/// Knows" is a direct, unfiltered view over this table (master prompt § 10,
/// § 34): nothing shown there should be a lie about what's actually stored.
@Model
final class MemoryFact {
    @Attribute(.unique) var id: UUID
    var content: String
    var kind: MemoryKind
    /// Freeform grouping for display ("travel", "scheduling", "money") —
    /// intentionally not a closed enum since new categories emerge from use.
    var category: String
    var confidence: ConfidenceLevel
    /// The user can turn a fact off without deleting it — it stops being
    /// used but stays inspectable.
    var isEnabled: Bool
    var sourceNoteID: String?
    var lastReferencedAt: Date?
    var provenance: Provenance
    var createdAt: Date
    var updatedAt: Date

    init(
        content: String,
        kind: MemoryKind,
        category: String = "general",
        confidence: ConfidenceLevel = .confirmed,
        sourceNoteID: String? = nil,
        provenance: Provenance = .userProvided,
        createdAt: Date = .now
    ) {
        self.id = UUID()
        self.content = content
        self.kind = kind
        self.category = category
        self.confidence = confidence
        self.isEnabled = true
        self.sourceNoteID = sourceNoteID
        self.lastReferencedAt = nil
        self.provenance = provenance
        self.createdAt = createdAt
        self.updatedAt = createdAt
    }
}
