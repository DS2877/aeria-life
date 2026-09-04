import Foundation

/// Infers the current `LifeMode` from time, calendar, and location — master
/// prompt § 14: "Modes should primarily be inferred... never trap users in
/// a mode." A manual override always wins outright; this function is pure
/// so it's trivially testable (see AeriaTests/LifeModeEngineTests).
enum LifeModeEngine {
    static func inferMode(
        now: Date = .now,
        calendar: Calendar = .current,
        todaysEvents: [CalendarEvent],
        nearestPlaceCategory: PlaceCategory?,
        manualOverride: LifeMode?
    ) -> LifeMode {
        if let manualOverride { return manualOverride }

        let hour = calendar.component(.hour, from: now)
        let weekday = calendar.component(.weekday, from: now)
        let isWeekend = weekday == 1 || weekday == 7

        if hour < 9 {
            return .morning
        }
        if hour >= 21 {
            return .evening
        }
        if isWeekend {
            return .weekend
        }
        if nearestPlaceCategory == .work {
            return .work
        }
        let hasWorkHoursMeeting = todaysEvents.contains { event in
            !event.isAllDay && calendar.isDate(event.startDate, inSameDayAs: now)
        }
        if hasWorkHoursMeeting, hour >= 9, hour < 18 {
            return .work
        }
        return .home
    }
}
