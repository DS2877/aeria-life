import Foundation
import SwiftData

/// One option within a decision — "buy" vs "lease," master prompt § 27.
/// A plain `Codable` struct stored as an array on `DecisionRecord` rather
/// than its own SwiftData model: options only ever exist in the context of
/// one decision, never queried or linked independently.
struct DecisionOption: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    var upfrontCost: Decimal?
    var monthlyCost: Decimal?
    var pros: [String] = []
    var cons: [String] = []
    var notes: String = ""
}

/// Master prompt § 27 "Help me decide": structures upfront cost, recurring
/// cost, pros/cons per option, then `DecisionEngine` computes a plain-cost
/// recommendation — never framed as professional advice.
@Model
final class DecisionRecord {
    @Attribute(.unique) var id: UUID
    var title: String
    var horizonMonths: Int
    var options: [DecisionOption]
    var notes: String
    var createdAt: Date
    var updatedAt: Date
    var isArchived: Bool

    init(title: String, horizonMonths: Int = 12, createdAt: Date = .now) {
        self.id = UUID()
        self.title = title
        self.horizonMonths = horizonMonths
        self.options = []
        self.notes = ""
        self.createdAt = createdAt
        self.updatedAt = createdAt
        self.isArchived = false
    }
}
