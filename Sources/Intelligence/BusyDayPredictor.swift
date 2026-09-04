import Foundation

/// Master prompt § 28 Predictions: "unusually busy days." Compares today's
/// timed-event count against the same weekday over the past several weeks
/// — "unusual" means meaningfully more than typical, not just "more than
/// zero more," so a Tuesday with 4 events when Tuesdays normally have 3
/// doesn't trigger this.
enum BusyDayPredictor {
    struct Assessment {
        let isUnusuallyBusy: Bool
        let todayCount: Int
        let typicalCount: Double
    }

    static func assess(todayCount: Int, recentSameWeekdayCounts: [Int]) -> Assessment {
        guard !recentSameWeekdayCounts.isEmpty else {
            return Assessment(isUnusuallyBusy: false, todayCount: todayCount, typicalCount: Double(todayCount))
        }
        let typical = Double(recentSameWeekdayCounts.reduce(0, +)) / Double(recentSameWeekdayCounts.count)
        let isUnusual = Double(todayCount) >= typical + 2 && Double(todayCount) > typical * 1.5
        return Assessment(isUnusuallyBusy: isUnusual, todayCount: todayCount, typicalCount: typical)
    }
}
