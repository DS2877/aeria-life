import Foundation
import SwiftData

/// A person in the user's life — never treated as a CRM record (master
/// prompt § 71). Deliberately thin: name, how Aeria should address the
/// relationship, and the few facts worth remembering. Everything else
/// (shared events, promises, gifts) hangs off `LifeRelationship`.
@Model
final class Person {
    @Attribute(.unique) var id: UUID
    var name: String
    /// Free text, not an enum — "sister", "landlord", "Anna from work".
    var relationshipLabel: String
    var birthday: DateComponents?
    var notes: String
    /// Optional link to the system Contacts record, once the user grants
    /// Contacts access (not requested in MVP — see docs/ROADMAP.md).
    var contactIdentifier: String?
    var provenance: Provenance
    var createdAt: Date
    var updatedAt: Date
    var isArchived: Bool

    init(
        name: String,
        relationshipLabel: String = "",
        birthday: DateComponents? = nil,
        notes: String = "",
        contactIdentifier: String? = nil,
        provenance: Provenance = .userProvided,
        createdAt: Date = .now
    ) {
        self.id = UUID()
        self.name = name
        self.relationshipLabel = relationshipLabel
        self.birthday = birthday
        self.notes = notes
        self.contactIdentifier = contactIdentifier
        self.provenance = provenance
        self.createdAt = createdAt
        self.updatedAt = createdAt
        self.isArchived = false
    }
}

/// An institution — insurer, bank, employer, retailer, utility. Mostly exists
/// so Vault documents and Subscriptions have somewhere to point ("insuredBy",
/// "purchasedFrom") without free-typing the same name everywhere.
@Model
final class Organization {
    @Attribute(.unique) var id: UUID
    var name: String
    var category: OrganizationCategory
    var website: String?
    var notes: String
    var provenance: Provenance
    var createdAt: Date
    var updatedAt: Date
    var isArchived: Bool

    init(
        name: String,
        category: OrganizationCategory,
        website: String? = nil,
        notes: String = "",
        provenance: Provenance = .userProvided,
        createdAt: Date = .now
    ) {
        self.id = UUID()
        self.name = name
        self.category = category
        self.website = website
        self.notes = notes
        self.provenance = provenance
        self.createdAt = createdAt
        self.updatedAt = createdAt
        self.isArchived = false
    }
}

enum OrganizationCategory: String, Codable, CaseIterable, Hashable {
    case insurer, bank, employer, retailer, utility, healthcare, government, service, other
}
