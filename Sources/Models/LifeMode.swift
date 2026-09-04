import Foundation

/// The user's inferred current context — master prompt § 14. Primarily
/// inferred by `LifeModeEngine` from time/calendar/location; manual override
/// is always allowed and never "traps" the user in a mode (§ 14).
enum LifeMode: String, Codable, CaseIterable, Hashable {
    case morning, work, home, travel, focus, weekend, evening

    var displayName: String {
        switch self {
        case .morning: return "Morning"
        case .work: return "Work"
        case .home: return "Home"
        case .travel: return "Travel"
        case .focus: return "Focus"
        case .weekend: return "Weekend"
        case .evening: return "Evening"
        }
    }

    var symbolName: String {
        switch self {
        case .morning: return "sunrise.fill"
        case .work: return "briefcase.fill"
        case .home: return "house.fill"
        case .travel: return "airplane"
        case .focus: return "moon.circle.fill"
        case .weekend: return "leaf.fill"
        case .evening: return "moon.stars.fill"
        }
    }
}
