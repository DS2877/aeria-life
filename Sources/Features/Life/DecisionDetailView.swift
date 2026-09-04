import SwiftUI

struct DecisionDetailView: View {
    @Bindable var decision: DecisionRecord
    @State private var isPresentingAddOption = false
    @State private var editingOptionID: UUID?

    private var recommendation: DecisionEngine.Recommendation? {
        DecisionEngine.recommend(options: decision.options, horizonMonths: decision.horizonMonths)
    }

    var body: some View {
        List {
            Section {
                Stepper(
                    "Compare over \(decision.horizonMonths) month\(decision.horizonMonths == 1 ? "" : "s")",
                    value: $decision.horizonMonths,
                    in: 1...120
                )
            }
            .listRowBackground(Palette.canvas)

            if let recommendation {
                Section("Aeria's read") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(recommendation.isCloseCall ? "Too close to call" : "Worth knowing")
                            .font(AeriaFont.captionEmphasized)
                            .foregroundStyle(recommendation.isCloseCall ? Palette.notice : Palette.accent)
                        Text(recommendation.reasoning)
                            .foregroundStyle(Palette.textPrimary)
                    }
                }
                .listRowBackground(Palette.canvas)
            }

            Section("Options") {
                ForEach(decision.options) { option in
                    Button {
                        editingOptionID = option.id
                    } label: {
                        optionRow(option)
                    }
                    .buttonStyle(.plain)
                }
                .onDelete { offsets in
                    decision.options.remove(atOffsets: offsets)
                }
                Button("Add Option") { isPresentingAddOption = true }
                    .foregroundStyle(Palette.accent)
            }
            .listRowBackground(Palette.canvas)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .navigationTitle(decision.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isPresentingAddOption) {
            DecisionOptionSheet(existing: nil) { option in
                decision.options.append(option)
            }
        }
        .sheet(item: Binding(
            get: { decision.options.first { $0.id == editingOptionID } },
            set: { _ in editingOptionID = nil }
        )) { existing in
            DecisionOptionSheet(existing: existing) { updated in
                if let index = decision.options.firstIndex(where: { $0.id == updated.id }) {
                    decision.options[index] = updated
                }
            }
        }
    }

    private func optionRow(_ option: DecisionOption) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(option.name).foregroundStyle(Palette.textPrimary)
                Text(costSummary(option))
                    .font(AeriaFont.caption)
                    .foregroundStyle(Palette.textSecondary)
            }
            Spacer()
            Text(formatted(DecisionEngine.totalCost(for: option, horizonMonths: decision.horizonMonths)))
                .font(AeriaFont.captionEmphasized)
                .foregroundStyle(Palette.textPrimary)
        }
    }

    private func costSummary(_ option: DecisionOption) -> String {
        var parts: [String] = []
        if let upfront = option.upfrontCost { parts.append("\(formatted(upfront)) upfront") }
        if let monthly = option.monthlyCost { parts.append("\(formatted(monthly))/mo") }
        return parts.isEmpty ? "No cost entered" : parts.joined(separator: " + ")
    }

    private func formatted(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = Locale.current.currency?.identifier ?? "USD"
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(amount)"
    }
}

private struct DecisionOptionSheet: View {
    @Environment(\.dismiss) private var dismiss
    let existing: DecisionOption?
    let onSave: (DecisionOption) -> Void

    @State private var name: String
    @State private var upfrontText: String
    @State private var monthlyText: String
    @State private var prosText: String
    @State private var consText: String

    init(existing: DecisionOption?, onSave: @escaping (DecisionOption) -> Void) {
        self.existing = existing
        self.onSave = onSave
        _name = State(initialValue: existing?.name ?? "")
        _upfrontText = State(initialValue: existing?.upfrontCost.map { "\($0)" } ?? "")
        _monthlyText = State(initialValue: existing?.monthlyCost.map { "\($0)" } ?? "")
        _prosText = State(initialValue: existing?.pros.joined(separator: "\n") ?? "")
        _consText = State(initialValue: existing?.cons.joined(separator: "\n") ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Option name", text: $name)
                TextField("Upfront cost", text: $upfrontText).keyboardType(.decimalPad)
                TextField("Monthly cost", text: $monthlyText).keyboardType(.decimalPad)
                Section("Pros") {
                    TextEditor(text: $prosText).frame(minHeight: 60)
                }
                Section("Cons") {
                    TextEditor(text: $consText).frame(minHeight: 60)
                }
            }
            .navigationTitle(existing == nil ? "Add Option" : "Edit Option")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        var option = existing ?? DecisionOption(name: name)
        option.name = name
        option.upfrontCost = Decimal(string: upfrontText)
        option.monthlyCost = Decimal(string: monthlyText)
        option.pros = prosText.split(separator: "\n").map(String.init)
        option.cons = consText.split(separator: "\n").map(String.init)
        onSave(option)
        dismiss()
    }
}
