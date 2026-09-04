import Foundation

/// Master prompt § 27: "Based on the information available, Option A
/// appears stronger because…" — a plain cost comparison over the user's
/// own numbers, never dressed up as financial advice. Pure and
/// deterministic, like `PriorityEngine`.
enum DecisionEngine {
    struct Recommendation {
        let bestOptionID: UUID
        let reasoning: String
        /// True when the gap between the top two options is small enough
        /// that Aeria says so explicitly rather than implying confidence
        /// it doesn't have.
        let isCloseCall: Bool
    }

    static func totalCost(for option: DecisionOption, horizonMonths: Int) -> Decimal {
        (option.upfrontCost ?? 0) + (option.monthlyCost ?? 0) * Decimal(horizonMonths)
    }

    static func recommend(options: [DecisionOption], horizonMonths: Int) -> Recommendation? {
        guard options.count >= 2 else { return nil }
        let ranked = options
            .map { (option: $0, total: totalCost(for: $0, horizonMonths: horizonMonths)) }
            .sorted { $0.total < $1.total }

        guard let cheapest = ranked.first, let runnerUp = ranked.dropFirst().first else { return nil }

        // Guard division by zero — if the cheapest option costs nothing,
        // any gap at all is meaningful, not a rounding artifact.
        let isCloseCall: Bool
        if cheapest.total == 0 {
            isCloseCall = runnerUp.total == 0
        } else {
            let percentGap = (runnerUp.total - cheapest.total) / cheapest.total
            isCloseCall = percentGap < Decimal(0.05)
        }

        let horizonText = horizonMonths == 12 ? "a year" : "\(horizonMonths) months"
        let reasoning = isCloseCall
            ? "\(cheapest.option.name) costs about the same as \(runnerUp.option.name) over \(horizonText) — close enough that other factors should probably decide this."
            : "\(cheapest.option.name) costs less over \(horizonText), based on what you entered."

        return Recommendation(bestOptionID: cheapest.option.id, reasoning: reasoning, isCloseCall: isCloseCall)
    }
}
