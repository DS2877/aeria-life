import EventKit
import Foundation

/// A lightweight, display-ready mirror of an `EKEvent`. Aeria never persists
/// calendar events into SwiftData — EventKit is the single source of truth
/// (master prompt § 20, § 61); this struct exists only so the rest of the
/// app doesn't import EventKit everywhere.
struct CalendarEvent: Identifiable, Hashable {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
    let isAllDay: Bool
    let location: String?
    let calendarTitle: String

    init(ekEvent: EKEvent) {
        self.id = ekEvent.eventIdentifier
        self.title = ekEvent.title ?? "Untitled"
        self.startDate = ekEvent.startDate
        self.endDate = ekEvent.endDate
        self.isAllDay = ekEvent.isAllDay
        self.location = ekEvent.location
        self.calendarTitle = ekEvent.calendar?.title ?? ""
    }
}

/// Reads Apple Calendar via EventKit. Read-mostly: Aeria's job is to add
/// intelligence over the calendar (§ 20), not to become a calendar app, so
/// writes are limited to events the user explicitly asks Aeria to create.
@MainActor
final class CalendarContextProvider: ObservableObject {
    private let store = EKEventStore()

    @Published private(set) var authorizationStatus: EKAuthorizationStatus =
        EKEventStore.authorizationStatus(for: .event)

    var isAuthorized: Bool { authorizationStatus == .fullAccess }

    func requestAccess() async -> Bool {
        do {
            let granted = try await store.requestFullAccessToEvents()
            authorizationStatus = EKEventStore.authorizationStatus(for: .event)
            return granted
        } catch {
            authorizationStatus = EKEventStore.authorizationStatus(for: .event)
            return false
        }
    }

    /// All events between `start` and `end`, sorted chronologically.
    func events(from start: Date, to end: Date) -> [CalendarEvent] {
        guard isAuthorized else { return [] }
        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        return store.events(matching: predicate)
            .sorted { $0.startDate < $1.startDate }
            .map(CalendarEvent.init)
    }

    /// Gaps of at least `minimumDuration` between events in the window —
    /// backs "find me a free evening" / Smart Calendar (§ 20, § 66).
    func freeIntervals(from start: Date, to end: Date, minimumDuration: TimeInterval) -> [DateInterval] {
        let busy = events(from: start, to: end)
            .filter { !$0.isAllDay }
            .sorted { $0.startDate < $1.startDate }

        var gaps: [DateInterval] = []
        var cursor = start
        for event in busy {
            if event.startDate > cursor {
                let gap = DateInterval(start: cursor, end: event.startDate)
                if gap.duration >= minimumDuration { gaps.append(gap) }
            }
            cursor = max(cursor, event.endDate)
        }
        if end > cursor {
            let gap = DateInterval(start: cursor, end: end)
            if gap.duration >= minimumDuration { gaps.append(gap) }
        }
        return gaps
    }

    /// Timed (non-all-day) event count for one specific day — the building
    /// block for "is today unusually busy" (`BusyDayPredictor`).
    func timedEventCount(on date: Date) -> Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? date
        return events(from: start, to: end).filter { !$0.isAllDay }.count
    }

    /// Event counts for the same weekday over each of the past `weeksBack`
    /// weeks — the "typical" baseline `BusyDayPredictor` compares today
    /// against.
    func pastSameWeekdayEventCounts(weeksBack: Int, from referenceDate: Date = .now) -> [Int] {
        let calendar = Calendar.current
        return (1...max(weeksBack, 1)).compactMap { weeksAgo in
            guard let date = calendar.date(byAdding: .weekOfYear, value: -weeksAgo, to: referenceDate) else { return nil }
            return timedEventCount(on: date)
        }
    }

    /// Creates a calendar event. Only ever called after the user has
    /// approved an Aeria action preview (master prompt § 30, § 67) — never
    /// silently.
    func createEvent(title: String, start: Date, end: Date, notes: String? = nil) throws -> String {
        let event = EKEvent(eventStore: store)
        event.title = title
        event.startDate = start
        event.endDate = end
        event.notes = notes
        event.calendar = store.defaultCalendarForNewEvents
        try store.save(event, span: .thisEvent)
        return event.eventIdentifier
    }
}
