import Foundation
import SwiftData

enum AssetCategory: String, Codable, CaseIterable, Hashable {
    case vehicle, electronics, appliance, bicycle, camera, sportsEquipment, furniture, other

    var displayName: String {
        switch self {
        case .vehicle: return "Vehicle"
        case .electronics: return "Electronics"
        case .appliance: return "Appliance"
        case .bicycle: return "Bicycle"
        case .camera: return "Camera"
        case .sportsEquipment: return "Sports Equipment"
        case .furniture: return "Furniture"
        case .other: return "Other"
        }
    }

    var symbolName: String {
        switch self {
        case .vehicle: return "car.fill"
        case .electronics: return "laptopcomputer"
        case .appliance: return "washer.fill"
        case .bicycle: return "bicycle"
        case .camera: return "camera.fill"
        case .sportsEquipment: return "figure.run"
        case .furniture: return "sofa.fill"
        case .other: return "cube.fill"
        }
    }
}

/// A possession worth Aeria remembering — master prompt § 17. Should feel
/// like a beautiful personal record, not an accounting ledger: purchase
/// memory, warranty, insurance, and service history all live on one object
/// so "is this still under warranty?" is a single lookup, not a search.
@Model
final class Asset {
    @Attribute(.unique) var id: UUID
    var name: String
    var category: AssetCategory
    var photoAssetFileNames: [String]

    var purchaseDate: Date?
    var purchasePrice: Decimal?
    var currencyCode: String
    var currentEstimate: Decimal?
    var purchasedFromOrganizationID: String?

    var warrantyExpiryDate: Date?
    var warrantyAttribution: FactAttribution?
    var insuranceOrganizationID: String?

    /// Free-form service history entries — kept simple rather than a full
    /// sub-model; each entry is one line the user or a scanned document adds.
    var serviceHistory: [ServiceEntry]

    var notes: String
    var provenance: Provenance
    var createdAt: Date
    var updatedAt: Date
    var isArchived: Bool

    init(
        name: String,
        category: AssetCategory,
        currencyCode: String = Locale.current.currency?.identifier ?? "USD",
        provenance: Provenance = .userProvided,
        createdAt: Date = .now
    ) {
        self.id = UUID()
        self.name = name
        self.category = category
        self.photoAssetFileNames = []
        self.purchaseDate = nil
        self.purchasePrice = nil
        self.currencyCode = currencyCode
        self.currentEstimate = nil
        self.purchasedFromOrganizationID = nil
        self.warrantyExpiryDate = nil
        self.warrantyAttribution = nil
        self.insuranceOrganizationID = nil
        self.serviceHistory = []
        self.notes = ""
        self.provenance = provenance
        self.createdAt = createdAt
        self.updatedAt = createdAt
        self.isArchived = false
    }
}

struct ServiceEntry: Codable, Identifiable {
    var id: UUID = UUID()
    var date: Date
    var summary: String
    var cost: Decimal?
}
