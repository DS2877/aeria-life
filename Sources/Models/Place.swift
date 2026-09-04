import Foundation
import SwiftData

/// A place worth Aeria knowing about — home, work, a recurring destination.
/// Not a full address book; just enough to power context (Life Modes,
/// "leave by" timing) and to anchor Moments/Assets ("home" owns "boiler").
@Model
final class Place {
    @Attribute(.unique) var id: UUID
    var name: String
    var category: PlaceCategory
    var address: String
    var latitude: Double?
    var longitude: Double?
    var provenance: Provenance
    var createdAt: Date
    var updatedAt: Date
    var isArchived: Bool

    init(
        name: String,
        category: PlaceCategory,
        address: String = "",
        latitude: Double? = nil,
        longitude: Double? = nil,
        provenance: Provenance = .userProvided,
        createdAt: Date = .now
    ) {
        self.id = UUID()
        self.name = name
        self.category = category
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.provenance = provenance
        self.createdAt = createdAt
        self.updatedAt = createdAt
        self.isArchived = false
    }
}

enum PlaceCategory: String, Codable, CaseIterable, Hashable {
    case home, work, family, frequent, travel, other
}
