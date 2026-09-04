import SwiftData
import SwiftUI

/// Master prompt § 26: "always distinguish known, estimated, assumed,
/// projected. Never present projections as guarantees." Every number this
/// screen produces is labeled "Projected" — nothing here is treated as a
/// fact anywhere else in the app.
struct LifeSimulatorView: View {
    private enum Scenario: String, CaseIterable, Hashable {
        case savings = "Savings Goal"
        case recurringCost = "Recurring Cost"
    }

    @Query(filter: #Predicate<Subscription> { $0.isActive }) private var subscriptions: [Subscription]
    @State private var scenario: Scenario = .savings

    @State private var currentAmountText = ""
    @State private var monthlyContributionText = ""
    @State private var goalAmountText = ""

    @State private var changeAmountText = ""

    private var currencyCode: String { subscriptions.first?.currencyCode ?? Locale.current.currency?.identifier ?? "USD" }

    var body: some View {
        Form {
            Section {
                Picker("Scenario", selection: $scenario) {
                    ForEach(Scenario.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
            }
            .listRowBackground(Palette.canvas)

            switch scenario {
            case .savings: savingsSection
            case .recurringCost: recurringCostSection
            }
        }
        .scrollContentBackground(.hidden)
        .navigationTitle("What If")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var savingsSection: some View {
        Section("What if I save toward a goal?") {
            TextField("Currently saved", text: $currentAmountText).keyboardType(.decimalPad)
            TextField("Saving per month", text: $monthlyContributionText).keyboardType(.decimalPad)
            TextField("Goal amount (optional)", text: $goalAmountText).keyboardType(.decimalPad)
        }
        .listRowBackground(Palette.canvas)

        if let projection {
            Section("Projected") {
                if let months = projection.monthsToGoal {
                    LabeledContent("Reach your goal in", value: months == 0 ? "Already there" : "about \(months) month\(months == 1 ? "" : "s")")
                }
                ForEach(projection.projectedBalances, id: \.months) { checkpoint in
                    LabeledContent("After \(checkpoint.months) months", value: formatted(checkpoint.amount))
                }
                Text("Assumes you keep saving the same amount every month with no other changes — a projection, not a guarantee.")
                    .font(AeriaFont.caption)
                    .foregroundStyle(Palette.textSecondary)
            }
            .listRowBackground(Palette.canvas)
        }
    }

    private var projection: LifeSimulator.SavingsProjection? {
        guard let current = Decimal(string: currentAmountText), let monthly = Decimal(string: monthlyContributionText) else { return nil }
        let goal = Decimal(string: goalAmountText)
        return LifeSimulator.projectSavings(currentAmount: current, monthlyContribution: monthly, goalAmount: goal)
    }

    @ViewBuilder
    private var recurringCostSection: some View {
        let currentTotal = subscriptions.reduce(Decimal(0)) { $0 + $1.monthlyEquivalentCost }

        Section("What if I add or remove a recurring cost?") {
            LabeledContent("Your current subscriptions", value: "\(formatted(currentTotal))/mo")
            TextField("Change (use a minus sign to remove)", text: $changeAmountText)
                .keyboardType(.numbersAndPunctuation)
        }
        .listRowBackground(Palette.canvas)

        if let change = Decimal(string: changeAmountText) {
            let impact = LifeSimulator.projectRecurringCostImpact(currentMonthlyTotal: currentTotal, changeAmount: change)
            Section("Projected") {
                LabeledContent("New monthly total", value: formatted(impact.newMonthly))
                LabeledContent("New annual total", value: formatted(impact.newAnnual))
                Text("Based on your currently tracked subscriptions — doesn't include one-off purchases or bills.")
                    .font(AeriaFont.caption)
                    .foregroundStyle(Palette.textSecondary)
            }
            .listRowBackground(Palette.canvas)
        }
    }

    private func formatted(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(amount)"
    }
}
