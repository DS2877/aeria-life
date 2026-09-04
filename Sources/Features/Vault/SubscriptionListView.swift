import SwiftData
import SwiftUI

/// Master prompt § 19 Subscription Radar: the annualized number is the
/// point — awareness, not budgeting.
struct SubscriptionListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Subscription.name) private var subscriptions: [Subscription]
    @State private var isPresentingAdd = false

    private var monthlyTotal: Decimal {
        subscriptions.filter(\.isActive).reduce(Decimal(0)) { $0 + $1.monthlyEquivalentCost }
    }

    /// Master prompt § 19: "Three subscriptions haven't appeared relevant
    /// recently." Aeria has no way to observe actual usage of another
    /// app, so this is a periodic self-check-in rather than an inferred
    /// fact — still real, since `lastRelevantAt` genuinely drives it,
    /// just honestly sourced from the user rather than pretending to be
    /// detected.
    private func needsCheckIn(_ subscription: Subscription) -> Bool {
        guard subscription.isActive else { return false }
        let staleDate = Calendar.current.date(byAdding: .day, value: -90, to: .now) ?? .now
        let reference = subscription.lastRelevantAt ?? subscription.createdAt
        return reference < staleDate
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Metrics.spacingL) {
                if !subscriptions.isEmpty {
                    SurfaceCard(isElevated: true) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("About \(formatted(monthlyTotal))/month")
                                .font(AeriaFont.title)
                                .foregroundStyle(Palette.textPrimary)
                            Text("\(formatted(monthlyTotal * 12))/year")
                                .font(AeriaFont.subheadline)
                                .foregroundStyle(Palette.textSecondary)
                        }
                    }
                }

                if subscriptions.isEmpty {
                    EmptyStateView(
                        symbolName: "arrow.triangle.2.circlepath",
                        title: "No subscriptions tracked",
                        message: "Add one to see what your recurring commitments really cost per year."
                    )
                    .padding(.top, Metrics.spacingXL)
                } else {
                    SurfaceCard {
                        VStack(alignment: .leading, spacing: Metrics.spacingM) {
                            ForEach(Array(subscriptions.enumerated()), id: \.element.id) { index, subscription in
                                if index > 0 { Divider().overlay(Palette.hairline) }
                                subscriptionRow(subscription)
                            }
                        }
                    }
                }
            }
            .padding(Metrics.screenPadding)
        }
        .navigationTitle("Subscriptions")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { isPresentingAdd = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $isPresentingAdd) {
            AddSubscriptionSheet()
        }
    }

    private func subscriptionRow(_ subscription: Subscription) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(subscription.name)
                        .font(AeriaFont.bodyEmphasized)
                        .foregroundStyle(subscription.isActive ? Palette.textPrimary : Palette.textTertiary)
                        .strikethrough(!subscription.isActive)
                    Text(subscription.isActive
                         ? "\(formatted(subscription.amount)) / \(subscription.frequency.rawValue)"
                         : "Canceled")
                        .font(AeriaFont.caption)
                        .foregroundStyle(Palette.textSecondary)
                }
                Spacer()
                if subscription.isActive {
                    Text(formatted(subscription.annualizedCost) + "/yr")
                        .font(AeriaFont.caption)
                        .foregroundStyle(Palette.textTertiary)
                }
            }

            if needsCheckIn(subscription) {
                HStack {
                    Text("Still using this?")
                        .font(AeriaFont.caption)
                        .foregroundStyle(Palette.notice)
                    Spacer()
                    Button("Yes") {
                        subscription.lastRelevantAt = .now
                        subscription.updatedAt = .now
                    }
                    .font(AeriaFont.captionEmphasized)
                    .buttonStyle(.bordered)
                    Button("No, cancel it") {
                        subscription.isActive = false
                        subscription.updatedAt = .now
                    }
                    .font(AeriaFont.captionEmphasized)
                    .buttonStyle(.bordered)
                    .tint(Palette.critical)
                }
            }
        }
    }

    private func formatted(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = subscriptions.first?.currencyCode ?? Locale.current.currency?.identifier ?? "USD"
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(amount)"
    }
}

private struct AddSubscriptionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var amountText = ""
    @State private var frequency: BillingFrequency = .monthly
    @State private var category: MoneyCategory = .streaming

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                TextField("Amount", text: $amountText).keyboardType(.decimalPad)
                Picker("Billed", selection: $frequency) {
                    ForEach(BillingFrequency.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) }
                }
                Picker("Category", selection: $category) {
                    ForEach(MoneyCategory.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) }
                }
            }
            .navigationTitle("Add Subscription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let amount = Decimal(string: amountText), !name.isEmpty {
                            modelContext.insert(Subscription(name: name, amount: amount, frequency: frequency, category: category))
                        }
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
