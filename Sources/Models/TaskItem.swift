import Foundation
import SwiftData

/// Aeria's own actionable item. This is deliberately *not* how every task in
/// the app is represented — a task the user wants in Apple Reminders should
/// live there (see ReminderContextProvider) and Aeria simply reads it back
/// via EventKit. `TaskItem` exists for things that start life inside Aeria
/// (a Life Inbox capture, a Loose End Aeria noticed) before the user decides
/// whether they belong in Reminders at all. See master prompt § 21, § 73.
@Model
final class TaskItem {
    @Attribute(.unique) var id: UUID
    var title: String
    var notes: String
    var dueDate: Date?
    var isCompleted: Bool
    var completedAt: Date?
    /// Set once the user promotes this into a real system reminder, so Aeria
    /// doesn't show the same thing twice.
    var linkedReminderIdentifier: String?
    var provenance: Provenance
    var createdAt: Date
    var updatedAt: Date
    var isArchived: Bool

    init(
        title: String,
        notes: String = "",
        dueDate: Date? = nil,
        provenance: Provenance = .userProvided,
        createdAt: Date = .now
    ) {
        self.id = UUID()
        self.title = title
        self.notes = notes
        self.dueDate = dueDate
        self.isCompleted = false
        self.completedAt = nil
        self.linkedReminderIdentifier = nil
        self.provenance = provenance
        self.createdAt = createdAt
        self.updatedAt = createdAt
        self.isArchived = false
    }
}

/// An explicit commitment the user made — "I'll send Anna the document this
/// week." Master prompt § 72 "Promises". Distinct from `TaskItem`: a
/// commitment is owed *to someone*, and Aeria's job is to notice it was made
/// and later check whether it was kept, not to schedule it.
@Model
final class Commitment {
    @Attribute(.unique) var id: UUID
    /// What was promised, in the user's own words where possible.
    var text: String
    /// Person id (Person.id.uuidString) this was promised to, if known.
    var toPersonID: String?
    /// Natural-language due hint as captured ("next week", "tomorrow") —
    /// kept alongside the resolved date since the resolution may be a guess.
    var dueHint: String
    var resolvedDueDate: Date?
    var isFulfilled: Bool
    var fulfilledAt: Date?
    /// Id of the NoteItem this was extracted from, for "Based on" drill-in.
    var sourceNoteID: String?
    var confidence: ConfidenceLevel
    var provenance: Provenance
    var createdAt: Date
    var updatedAt: Date
    var isArchived: Bool

    init(
        text: String,
        toPersonID: String? = nil,
        dueHint: String = "",
        resolvedDueDate: Date? = nil,
        sourceNoteID: String? = nil,
        confidence: ConfidenceLevel = .confirmed,
        provenance: Provenance = .userProvided,
        createdAt: Date = .now
    ) {
        self.id = UUID()
        self.text = text
        self.toPersonID = toPersonID
        self.dueHint = dueHint
        self.resolvedDueDate = resolvedDueDate
        self.isFulfilled = false
        self.fulfilledAt = nil
        self.sourceNoteID = sourceNoteID
        self.confidence = confidence
        self.provenance = provenance
        self.createdAt = createdAt
        self.updatedAt = createdAt
        self.isArchived = false
    }
}
