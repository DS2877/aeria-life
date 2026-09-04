import Foundation
import SwiftData

enum MomentCategory: String, Codable, CaseIterable {
    case trip, move, wedding, newJob, newCar, renovation, majorPurchase, holiday, project, other

    var displayName: String {
        switch self {
        case .trip: return "Trip"
        case .move: return "Move"
        case .wedding: return "Wedding"
        case .newJob: return "New Job"
        case .newCar: return "New Car"
        case .renovation: return "Renovation"
        case .majorPurchase: return "Major Purchase"
        case .holiday: return "Holiday"
        case .project: return "Project"
        case .other: return "Moment"
        }
    }

    var symbolName: String {
        switch self {
        case .trip, .holiday: return "airplane"
        case .move: return "shippingbox.fill"
        case .wedding: return "heart.fill"
        case .newJob: return "briefcase.fill"
        case .newCar: return "car.fill"
        case .renovation: return "hammer.fill"
        case .majorPurchase: return "bag.fill"
        case .project: return "checklist"
        case .other: return "sparkles"
        }
    }
}

/// A temporary context cluster — master prompt § 24. A Moment is the one
/// entity type that exists purely to gather other entities together (via
/// `LifeRelationship`, predicate `.relatedTo` or `.belongsTo`): the tasks,
/// documents, events, people, and expenses tied to one trip or project live
/// together without the user filing anything by hand.
@Model
final class Moment {
    @Attribute(.unique) var id: UUID
    var title: String
    var category: MomentCategory
    var startDate: Date?
    var endDate: Date?
    var summary: String
    var isActive: Bool
    var provenance: Provenance
    var createdAt: Date
    var updatedAt: Date
    var isArchived: Bool

    init(
        title: String,
        category: MomentCategory,
        startDate: Date? = nil,
        endDate: Date? = nil,
        provenance: Provenance = .userProvided,
        createdAt: Date = .now
    ) {
        self.id = UUID()
        self.title = title
        self.category = category
        self.startDate = startDate
        self.endDate = endDate
        self.summary = ""
        self.isActive = true
        self.provenance = provenance
        self.createdAt = createdAt
        self.updatedAt = createdAt
        self.isArchived = false
    }
}
