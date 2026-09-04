import Foundation
import SwiftData

enum GoalCategory: String, Codable, CaseIterable, Hashable {
    case health, financial, learning, travel, home, career, other
}

/// A meaningful goal — master prompt § 25. Aeria turns this into
/// context-aware nudges ("two good windows this week"), never a gamified
/// streak or badge system.
@Model
final class Goal {
    @Attribute(.unique) var id: UUID
    var title: String
    var category: GoalCategory
    var targetDate: Date?
    /// Optional quantitative target ("50000" + unit "SEK", "10" + unit "km").
    var targetValue: Double?
    var targetUnit: String?
    var currentValue: Double?
    var notes: String
    var isCompleted: Bool
    var completedAt: Date?
    var provenance: Provenance
    var createdAt: Date
    var updatedAt: Date
    var isArchived: Bool

    init(
        title: String,
        category: GoalCategory,
        targetDate: Date? = nil,
        targetValue: Double? = nil,
        targetUnit: String? = nil,
        provenance: Provenance = .userProvided,
        createdAt: Date = .now
    ) {
        self.id = UUID()
        self.title = title
        self.category = category
        self.targetDate = targetDate
        self.targetValue = targetValue
        self.targetUnit = targetUnit
        self.currentValue = nil
        self.notes = ""
        self.isCompleted = false
        self.completedAt = nil
        self.provenance = provenance
        self.createdAt = createdAt
        self.updatedAt = createdAt
        self.isArchived = false
    }
}

enum HabitCadence: String, Codable, CaseIterable, Hashable {
    case daily, weekdays, weekly, custom
}

/// A recurring practice the user wants help sustaining. Deliberately has no
/// streak-counter UI surface (master prompt § 25, § 69) — `completionDates`
/// exists so the Priority Engine can find good windows, not to gamify.
@Model
final class Habit {
    @Attribute(.unique) var id: UUID
    var title: String
    var cadence: HabitCadence
    var targetCountPerPeriod: Int
    var completionDates: [Date]
    var notes: String
    var provenance: Provenance
    var createdAt: Date
    var updatedAt: Date
    var isArchived: Bool

    init(
        title: String,
        cadence: HabitCadence,
        targetCountPerPeriod: Int = 1,
        provenance: Provenance = .userProvided,
        createdAt: Date = .now
    ) {
        self.id = UUID()
        self.title = title
        self.cadence = cadence
        self.targetCountPerPeriod = targetCountPerPeriod
        self.completionDates = []
        self.notes = ""
        self.provenance = provenance
        self.createdAt = createdAt
        self.updatedAt = createdAt
        self.isArchived = false
    }
}
