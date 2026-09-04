import SwiftData
import SwiftUI

/// Master prompt § 25: goals with no gamification. Progress is a plain
/// number, not a ring or a streak.
struct GoalsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Goal> { !$0.isArchived }, sort: \Goal.createdAt, order: .reverse) private var goals: [Goal]
    @State private var isPresentingAdd = false

    var body: some View {
        Group {
            if goals.isEmpty {
                EmptyStateView(symbolName: "target", title: "No goals yet", message: "Add something you're working toward.")
                    .padding(.top, Metrics.spacingXXL)
            } else {
                List {
                    ForEach(goals) { goal in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(goal.title)
                                    .foregroundStyle(goal.isCompleted ? Palette.textTertiary : Palette.textPrimary)
                                    .strikethrough(goal.isCompleted)
                                Spacer()
                                Button {
                                    goal.isCompleted.toggle()
                                    goal.completedAt = goal.isCompleted ? .now : nil
                                } label: {
                                    Image(systemName: goal.isCompleted ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(goal.isCompleted ? Palette.positive : Palette.textTertiary)
                                }
                                .buttonStyle(.plain)
                            }
                            if let target = goal.targetValue {
                                let current = goal.currentValue ?? 0
                                Text("\(Int(current))\(goal.targetUnit ?? "") of \(Int(target))\(goal.targetUnit ?? "")")
                                    .font(AeriaFont.caption)
                                    .foregroundStyle(Palette.textSecondary)
                            }
                            if let date = goal.targetDate {
                                Text("By \(date.formatted(date: .abbreviated, time: .omitted))")
                                    .font(AeriaFont.caption)
                                    .foregroundStyle(Palette.textTertiary)
                            }
                        }
                        .listRowBackground(Palette.canvas)
                    }
                    .onDelete { offsets in
                        for index in offsets { goals[index].isArchived = true }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Goals")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { isPresentingAdd = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $isPresentingAdd) {
            AddGoalSheet()
        }
    }
}

private struct AddGoalSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var title = ""
    @State private var category: GoalCategory = .health
    @State private var hasTargetDate = false
    @State private var targetDate = Date().addingTimeInterval(30 * 86400)
    @State private var targetValueText = ""
    @State private var targetUnit = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Goal", text: $title)
                Picker("Category", selection: $category) {
                    ForEach(GoalCategory.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) }
                }
                Toggle("Has a target date", isOn: $hasTargetDate)
                if hasTargetDate {
                    DatePicker("Target date", selection: $targetDate, displayedComponents: .date)
                }
                Section("Optional target") {
                    TextField("Amount (e.g. 50000, 10)", text: $targetValueText)
                        .keyboardType(.decimalPad)
                    TextField("Unit (e.g. SEK, km)", text: $targetUnit)
                }
            }
            .navigationTitle("Add Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        modelContext.insert(Goal(
            title: title,
            category: category,
            targetDate: hasTargetDate ? targetDate : nil,
            targetValue: Double(targetValueText),
            targetUnit: targetUnit.isEmpty ? nil : targetUnit
        ))
        dismiss()
    }
}
