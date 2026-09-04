import Foundation
import SwiftData

/// Thin service over `MemoryFact` for the operations master prompt § 10
/// names explicitly: inspect, edit, correct, forget, disable a category.
/// "What Aeria Knows" (PrivacyCenter) is a direct view over exactly this —
/// no separate cache, no derived summary that could drift from the truth.
@MainActor
final class MemoryStore {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    @discardableResult
    func remember(
        _ content: String,
        kind: MemoryKind,
        category: String = "general",
        confidence: ConfidenceLevel = .confirmed,
        sourceNoteID: String? = nil,
        provenance: Provenance = .userProvided
    ) -> MemoryFact {
        let fact = MemoryFact(
            content: content,
            kind: kind,
            category: category,
            confidence: confidence,
            sourceNoteID: sourceNoteID,
            provenance: provenance
        )
        context.insert(fact)
        return fact
    }

    func forget(_ fact: MemoryFact) {
        context.delete(fact)
    }

    func setEnabled(_ isEnabled: Bool, for fact: MemoryFact) {
        fact.isEnabled = isEnabled
        fact.updatedAt = .now
    }

    /// Disables every fact in a category in one action — master prompt § 10
    /// "disable categories."
    func disableCategory(_ category: String, facts: [MemoryFact]) {
        for fact in facts where fact.category == category {
            fact.isEnabled = false
            fact.updatedAt = .now
        }
    }

    func markReferenced(_ fact: MemoryFact) {
        fact.lastReferencedAt = .now
    }

    /// Deletes everything — master prompt § 34 Privacy Center "Delete
    /// everything." Scoped to memory only; callers compose this with
    /// deleting other entities for a full wipe.
    func forgetEverything(facts: [MemoryFact]) {
        for fact in facts { context.delete(fact) }
    }
}
