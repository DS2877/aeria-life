import Foundation

/// Master prompt § 29: "notify when the value of interruption is greater
/// than the cost." This makes that comparison concrete instead of aspirational
/// copy — every proactive notification must clear all three bars below
/// before it's allowed to fire.
struct InterruptionBudget {
    /// Proactive notifications Aeria will send in a day, regardless of how
    /// many items would otherwise qualify.
    var maxPerDay: Int = 3
    /// Priority score (see PriorityEngine) required — deliberately higher
    /// than the bar for merely appearing on Today, since an interruption
    /// costs more than a line on a screen the user opened voluntarily.
    var minimumScore: Double = 0.6
    /// Don't stack notifications close together even if several qualify.
    var minimumSpacing: TimeInterval = 45 * 60
}

enum InterruptionDecision {
    static func shouldNotify(
        score: Double,
        sentToday: Int,
        lastSentAt: Date?,
        now: Date = .now,
        budget: InterruptionBudget = InterruptionBudget()
    ) -> Bool {
        guard score >= budget.minimumScore else { return false }
        guard sentToday < budget.maxPerDay else { return false }
        if let lastSentAt, now.timeIntervalSince(lastSentAt) < budget.minimumSpacing {
            return false
        }
        return true
    }
}
