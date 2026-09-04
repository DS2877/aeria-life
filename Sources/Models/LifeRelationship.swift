import Foundation
import SwiftData

/// Every persisted Life Graph entity, plus the two "virtual" kinds that live
/// in EventKit rather than SwiftData (see docs/ARCHITECTURE.md § Life Graph
/// for why calendar events and reminders aren't duplicated into our store).
/// `id` values for `.event`/`.reminder` are EventKit identifiers, not UUIDs.
enum LifeEntityType: String, Codable, CaseIterable, Hashable {
    case person, organization, place
    case event, reminder // EventKit-backed, not persisted here
    case task, commitment
    case document, asset, subscription, payment
    case goal, habit
    case moment, note, routine
    case memoryFact
    case decision
}

/// The verbs that connect two Life Graph nodes — master prompt § 4. Kept as
/// a flat vocabulary rather than per-entity typed relationships so new
/// connections don't require a schema migration.
enum LifeRelationshipKind: String, Codable, CaseIterable, Hashable {
    case owns, belongsTo
    case occursAt, occursOn
    case expiresOn, renewsOn
    case costs, requires
    case relatedTo
    case purchasedFrom, insuredBy, servicedBy
    case mentionedIn, createdFrom
    case dependsOn, conflictsWith
    case follows, precedes
}

/// One edge in the Life Graph: `subject --predicate--> object`. This table
/// *is* the graph — entities themselves stay simple, standalone SwiftData
/// models, and everything that connects them lives here. Never exposed to
/// the user as "graph"/"edge"/"triple" language (master prompt § 4).
@Model
final class LifeRelationship {
    @Attribute(.unique) var id: UUID
    var subjectID: String
    var subjectType: LifeEntityType
    var predicate: LifeRelationshipKind
    var objectID: String
    var objectType: LifeEntityType
    var createdAt: Date
    var provenance: Provenance
    /// Free text only when the predicate alone doesn't carry the meaning
    /// (e.g. `.costs` pairs with an amount stored on the object already, so
    /// this is usually empty).
    var note: String

    init(
        subjectID: String,
        subjectType: LifeEntityType,
        predicate: LifeRelationshipKind,
        objectID: String,
        objectType: LifeEntityType,
        provenance: Provenance,
        note: String = "",
        createdAt: Date = .now
    ) {
        self.id = UUID()
        self.subjectID = subjectID
        self.subjectType = subjectType
        self.predicate = predicate
        self.objectID = objectID
        self.objectType = objectType
        self.provenance = provenance
        self.note = note
        self.createdAt = createdAt
    }
}
