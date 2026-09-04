import ActivityKit
import Foundation

/// Starts/updates/ends the travel Live Activity as `TodayViewModel`'s
/// `travelPlan` changes — called from `TodayView` right alongside the
/// existing "leave by" card logic, using the exact same 90-minute imminence
/// window (`TodayView.aeriaObservation`) so the Live Activity never shows
/// something the app itself wouldn't already be leading with.
@MainActor
enum TravelActivityCoordinator {
    private static var currentActivity: Activity<TravelActivityAttributes>?

    static func update(with plan: TravelPlan?) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        guard let plan, plan.leaveByDate > .now, plan.leaveByDate.timeIntervalSince(.now) < 90 * 60 else {
            end()
            return
        }

        let state = TravelActivityAttributes.ContentState(
            minutesRemaining: plan.travelMinutes,
            leaveByDate: plan.leaveByDate
        )

        if let currentActivity {
            let content = ActivityContent(state: state, staleDate: plan.leaveByDate)
            Task { await currentActivity.update(content) }
            return
        }

        let attributes = TravelActivityAttributes(eventTitle: plan.eventTitle)
        let content = ActivityContent(state: state, staleDate: plan.leaveByDate)
        currentActivity = try? Activity.request(attributes: attributes, content: content)
    }

    static func end() {
        guard let activity = currentActivity else { return }
        currentActivity = nil
        Task { await activity.end(nil, dismissalPolicy: .default) }
    }
}
