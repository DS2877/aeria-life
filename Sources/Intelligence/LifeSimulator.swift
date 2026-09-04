import Foundation

/// Master prompt § 26 "Life Simulator": models a scenario using numbers the
/// user gives it, and is explicit that the result is a projection, not a
/// guarantee. Pure math, no persistence — a scenario is re-run fresh every
/// time rather than saved, since the whole point is "what if," not a
/// record to revisit (unlike `DecisionRecord`, which is a real comparison
/// worth keeping).
enum LifeSimulator {
    struct SavingsProjection {
        /// Nil if there's no goal amount, or the monthly contribution is
        /// zero/negative (the goal would never be reached).
        let monthsToGoal: Int?
        /// Projected balance at a few standard checkpoints.
        let projectedBalances: [(months: Int, amount: Decimal)]
    }

    static func projectSavings(currentAmount: Decimal, monthlyContribution: Decimal, goalAmount: Decimal?) -> SavingsProjection {
        var monthsToGoal: Int?
        if let goalAmount, monthlyContribution > 0 {
            let remaining = goalAmount - currentAmount
            if remaining <= 0 {
                monthsToGoal = 0
            } else {
                let remainingDouble = NSDecimalNumber(decimal: remaining).doubleValue
                let monthlyDouble = NSDecimalNumber(decimal: monthlyContribution).doubleValue
                monthsToGoal = Int((remainingDouble / monthlyDouble).rounded(.up))
            }
        }

        let checkpoints = [6, 12, 24, 60]
        let balances = checkpoints.map { months in
            (months: months, amount: currentAmount + monthlyContribution * Decimal(months))
        }

        return SavingsProjection(monthsToGoal: monthsToGoal, projectedBalances: balances)
    }

    /// "What if I add/remove this recurring cost?" — master prompt § 18
    /// Money Intelligence applied forward instead of backward.
    static func projectRecurringCostImpact(currentMonthlyTotal: Decimal, changeAmount: Decimal) -> (newMonthly: Decimal, newAnnual: Decimal) {
        let newMonthly = currentMonthlyTotal + changeAmount
        return (newMonthly, newMonthly * 12)
    }
}
