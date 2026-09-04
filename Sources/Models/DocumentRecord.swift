import Foundation
import SwiftData

enum DocumentCategory: String, Codable, CaseIterable, Hashable, Identifiable {
    var id: Self { self }

    case document, receipt, warranty, insurance, contract
    case vehicle, home, electronics, purchase, travel, identity, other

    var displayName: String {
        switch self {
        case .document: return "Document"
        case .receipt: return "Receipt"
        case .warranty: return "Warranty"
        case .insurance: return "Insurance"
        case .contract: return "Contract"
        case .vehicle: return "Vehicle"
        case .home: return "Home"
        case .electronics: return "Electronics"
        case .purchase: return "Purchase"
        case .travel: return "Travel"
        case .identity: return "Identity"
        case .other: return "Other"
        }
    }

    var symbolName: String {
        switch self {
        case .document: return "doc.text"
        case .receipt: return "receipt"
        case .warranty: return "checkmark.shield"
        case .insurance: return "shield.lefthalf.filled"
        case .contract: return "signature"
        case .vehicle: return "car.fill"
        case .home: return "house.fill"
        case .electronics: return "laptopcomputer"
        case .purchase: return "bag.fill"
        case .travel: return "airplane"
        case .identity: return "person.text.rectangle"
        case .other: return "folder.fill"
        }
    }
}

/// One item in the Vault. Master prompt § 15–16: import/scan a document,
/// extract what we can, always show low-confidence fields for confirmation
/// rather than presenting a guess as settled fact.
///
/// The binary (PDF/image) is *not* stored as SwiftData attribute data — it
/// lives in the app's Documents directory (or a CloudKit asset once sync is
/// enabled) and `storageFileName` points at it. Keeping large blobs out of
/// the SwiftData store keeps queries and CloudKit sync fast.
@Model
final class DocumentRecord {
    @Attribute(.unique) var id: UUID
    var title: String
    var category: DocumentCategory
    /// Filename under the app's Vault storage directory. See
    /// VaultStorage.url(for:).
    var storageFileName: String
    var thumbnailData: Data?

    var issuerOrganizationID: String?
    var relatedAssetID: String?
    var relatedPersonID: String?

    var documentDate: Date?
    var expiryDate: Date?
    var expiryAttribution: FactAttribution?
    var amount: Decimal?
    var amountAttribution: FactAttribution?
    var currencyCode: String

    var notes: String
    /// True while any extracted field's confidence is `.low` and hasn't been
    /// confirmed by the user yet — drives the Vault "needs review" badge.
    var needsReview: Bool

    var provenance: Provenance
    var createdAt: Date
    var updatedAt: Date
    var isArchived: Bool

    init(
        title: String,
        category: DocumentCategory,
        storageFileName: String,
        currencyCode: String = Locale.current.currency?.identifier ?? "USD",
        provenance: Provenance = .userProvided,
        createdAt: Date = .now
    ) {
        self.id = UUID()
        self.title = title
        self.category = category
        self.storageFileName = storageFileName
        self.thumbnailData = nil
        self.issuerOrganizationID = nil
        self.relatedAssetID = nil
        self.relatedPersonID = nil
        self.documentDate = nil
        self.expiryDate = nil
        self.expiryAttribution = nil
        self.amount = nil
        self.amountAttribution = nil
        self.currencyCode = currencyCode
        self.notes = ""
        self.needsReview = false
        self.provenance = provenance
        self.createdAt = createdAt
        self.updatedAt = createdAt
        self.isArchived = false
    }
}
