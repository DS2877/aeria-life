import EventKit
import Foundation

/// A lightweight, display-ready mirror of an `EKReminder`. Same rationale as
/// `CalendarEvent`: Apple Reminders is the source of truth, Aeria overlays
/// intelligence rather than duplicating storage (master prompt § 21).
struct LifeReminder: Identifiable, Hashable {
    let id: String
    let title: String
    let dueDate: Date?
    let isCompleted: Bool
    let notes: String?
    let listTitle: String

    init(ekReminder: EKReminder) {
        self.id = ekReminder.calendarItemIdentifier
        self.title = ekReminder.title ?? "Untitled"
        self.dueDate = ekReminder.dueDateComponents.flatMap { Calendar.current.date(from: $0) }
        self.isCompleted = ekReminder.isCompleted
        self.notes = ekReminder.notes
        self.listTitle = ekReminder.calendar?.title ?? ""
    }
}

/// Reads and writes Apple Reminders via EventKit. `TaskItem` (SwiftData) is
/// for things that haven't been promoted to a real reminder yet; once the
/// user promotes one, it lives here instead, and Aeria stops showing the
/// `TaskItem` copy (see `TaskItem.linkedReminderIdentifier`).
@MainActor
final class ReminderContextProvider: ObservableObject {
    private let store = EKEventStore()

    @Published private(set) var authorizationStatus: EKAuthorizationStatus =
        EKEventStore.authorizationStatus(for: .reminder)

    var isAuthorized: Bool { authorizationStatus == .fullAccess }

    func requestAccess() async -> Bool {
        do {
            let granted = try await store.requestFullAccessToReminders()
            authorizationStatus = EKEventStore.authorizationStatus(for: .reminder)
            return granted
        } catch {
            authorizationStatus = EKEventStore.authorizationStatus(for: .reminder)
            return false
        }
    }

    /// All incomplete reminders across every list.
    func fetchIncompleteReminders() async -> [LifeReminder] {
        guard isAuthorized else { return [] }
        let predicate = store.predicateForIncompleteReminders(withDueDateStarting: nil, ending: nil, calendars: nil)
        return await withCheckedContinuation { continuation in
            store.fetchReminders(matching: predicate) { ekReminders in
                let reminders = (ekReminders ?? [])
                    .map(LifeReminder.init)
                    .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
                continuation.resume(returning: reminders)
            }
        }
    }

    /// Creates a system reminder — used when the user promotes a `TaskItem`
    /// or Life Inbox capture into Reminders. Returns the new identifier so
    /// the caller can link it and stop showing its own copy.
    @discardableResult
    func createReminder(title: String, dueDate: Date? = nil, notes: String? = nil) throws -> String {
        let reminder = EKReminder(eventStore: store)
        reminder.title = title
        reminder.notes = notes
        if let dueDate {
            reminder.dueDateComponents = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute], from: dueDate
            )
        }
        reminder.calendar = store.defaultCalendarForNewReminders()
        try store.save(reminder, commit: true)
        return reminder.calendarItemIdentifier
    }

    func markCompleted(identifier: String) throws {
        guard let reminder = store.calendarItem(withIdentifier: identifier) as? EKReminder else { return }
        reminder.isCompleted = true
        try store.save(reminder, commit: true)
    }
}
