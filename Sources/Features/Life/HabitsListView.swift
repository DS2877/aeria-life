import SwiftData
import SwiftUI

/// Master prompt § 25: "no excessive streaks... instead, two good windows
/// this week." This screen shows only a plain completion count for today,
/// not a streak counter — logging is for the Priority Engine to reason
/// about later, not for the user to feel bad about breaking.
struct HabitsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Habit> { !$0.isArchived }) private var habits: [Habit]
    @State private var isPresentingAdd = false

    var body: some View {
        Group {
            if habits.isEmpty {
                EmptyStateView(symbolName: "repeat", title: "No habits yet", message: "Add something you want help sustaining.")
                    .padding(.top, Metrics.spacingXXL)
            } else {
                List {
                    ForEach(habits) { habit in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(habit.title).foregroundStyle(Palette.textPrimary)
                                Text(habit.cadence.rawValue.capitalized)
                                    .font(AeriaFont.caption)
                                    .foregroundStyle(Palette.textSecondary)
                            }
                            Spacer()
                            Button {
                                habit.completionDates.append(.now)
                            } label: {
                                Image(systemName: didCompleteToday(habit) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(didCompleteToday(habit) ? Palette.positive : Palette.textTertiary)
                            }
                            .buttonStyle(.plain)
                            .disabled(didCompleteToday(habit))
                        }
                        .listRowBackground(Palette.canvas)
                    }
                    .onDelete { offsets in
                        for index in offsets { habits[index].isArchived = true }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Habits")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { isPresentingAdd = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $isPresentingAdd) {
            AddHabitSheet()
        }
    }

    private func didCompleteToday(_ habit: Habit) -> Bool {
        habit.completionDates.contains { Calendar.current.isDateInToday($0) }
    }
}

private struct AddHabitSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var title = ""
    @State private var cadence: HabitCadence = .daily

    var body: some View {
        NavigationStack {
            Form {
                TextField("Habit", text: $title)
                Picker("Cadence", selection: $cadence) {
                    ForEach(HabitCadence.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) }
                }
            }
            .navigationTitle("Add Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        modelContext.insert(Habit(title: title, cadence: cadence))
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
