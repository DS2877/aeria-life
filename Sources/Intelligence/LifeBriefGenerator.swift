import Foundation

/// Master prompt § 6, § 12: the greeting and brief adapt to time of day, and
/// stay calm rather than enthusiastic. Pure string/date logic — no fetching
/// — so TodayViewModel assembles the data and this just phrases it.
enum LifeBriefGenerator {
    static func greeting(now: Date = .now, calendar: Calendar = .current) -> String {
        switch calendar.component(.hour, from: now) {
        case 0..<12: return "Good morning"
        case 12..<18: return "Here's what's next"
        default: return "Your evening"
        }
    }

    /// One calm, specific line for the "Worth knowing" section — never more
    /// than what's given; this only formats, it never invents the
    /// underlying fact.
    static func worthKnowingLine(weather: WeatherSnapshot?) -> String? {
        weather?.notableChangeHint
    }
}
