import Foundation
import UserNotifications

/// Local notifications only for the MVP — no APNs/remote push, so no server
/// and no extra Apple Developer capability is required to build and run
/// this. Every call site should have already passed `InterruptionDecision`.
@MainActor
final class NotificationScheduler {
    private let center = UNUserNotificationCenter.current()

    func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
    }

    func schedule(title: String, body: String, at date: Date, identifier: String) {
        guard date > .now else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute], from: date
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        center.add(request)
    }

    /// Fires shortly after being scheduled rather than at a specific
    /// calendar time — what a background-refresh-triggered proactive
    /// notification (master prompt § 29) wants, as opposed to `schedule`'s
    /// future-calendar-date shape.
    func scheduleNearImmediate(title: String, body: String, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        center.add(request)
    }

    /// A real, repeating daily reminder — what backs a time-based `Routine`
    /// (master prompt § 78). Hour/minute only in the trigger's date
    /// components is what makes `UNCalendarNotificationTrigger` repeat
    /// every day at that time rather than firing once.
    func scheduleDaily(title: String, body: String, hour: Int, minute: Int, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        center.add(request)
    }

    func cancel(identifier: String) {
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}
