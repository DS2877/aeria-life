import SwiftData
import SwiftUI

/// Master prompt § 78: "natural language should create automations." A
/// Routine is always descriptive; when it carries a daily time, it's also a
/// real repeating local notification (see `Routine`'s doc comment for why
/// that's the one trigger type this app executes without a bigger
/// permission ask).
struct RoutinesListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Routine> { !$0.isArchived }, sort: \Routine.createdAt, order: .reverse)
    private var routines: [Routine]
    @State private var isPresentingAdd = false

    var body: some View {
        Group {
            if routines.isEmpty {
                EmptyStateView(
                    symbolName: "repeat.circle",
                    title: "No routines yet",
                    message: "Describe a pattern — \"every morning around 7\" — and Aeria can remind you at that time."
                )
                .padding(.top, Metrics.spacingXXL)
            } else {
                List {
                    ForEach(routines) { routine in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(routine.name).foregroundStyle(Palette.textPrimary)
                                Spacer()
                                Toggle("", isOn: Binding(
                                    get: { routine.isEnabled },
                                    set: { setEnabled($0, for: routine) }
                                ))
                                .labelsHidden()
                            }
                            Text(routine.triggerDescription)
                                .font(AeriaFont.caption)
                                .foregroundStyle(Palette.textSecondary)
                            if routine.hasScheduledReminder, let hour = routine.reminderHour, let minute = routine.reminderMinute {
                                Label(
                                    String(format: "Reminds you daily at %02d:%02d", hour, minute),
                                    systemImage: "bell.fill"
                                )
                                .font(AeriaFont.caption)
                                .foregroundStyle(Palette.accent)
                            }
                        }
                        .listRowBackground(Palette.canvas)
                    }
                    .onDelete { offsets in
                        for index in offsets {
                            let routine = routines[index]
                            NotificationScheduler().cancel(identifier: routine.notificationIdentifier)
                            routine.isArchived = true
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Routines")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { isPresentingAdd = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $isPresentingAdd) {
            AddRoutineSheet()
        }
    }

    private func setEnabled(_ isEnabled: Bool, for routine: Routine) {
        routine.isEnabled = isEnabled
        routine.updatedAt = .now
        let scheduler = NotificationScheduler()
        if isEnabled, routine.hasScheduledReminder, let hour = routine.reminderHour, let minute = routine.reminderMinute {
            scheduler.scheduleDaily(
                title: routine.name,
                body: routine.actionDescription.isEmpty ? routine.triggerDescription : routine.actionDescription,
                hour: hour,
                minute: minute,
                identifier: routine.notificationIdentifier
            )
        } else {
            scheduler.cancel(identifier: routine.notificationIdentifier)
        }
    }
}

private struct AddRoutineSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var triggerDescription = ""
    @State private var actionDescription = ""
    @State private var wantsDailyReminder = false
    @State private var reminderTime = Date()

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name (e.g. Morning routine)", text: $name)
                TextField("When (e.g. every morning around 7)", text: $triggerDescription)
                TextField("What should happen", text: $actionDescription, axis: .vertical)

                Section {
                    Toggle("Remind me daily at a set time", isOn: $wantsDailyReminder)
                    if wantsDailyReminder {
                        DatePicker("Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    }
                } footer: {
                    Text("This is the one trigger Aeria can act on directly — a daily time. \"When I get home\" style triggers are noted but not yet automatic.")
                }
            }
            .navigationTitle("New Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { Task { await save() } }
                        .fontWeight(.semibold)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() async {
        let routine = Routine(name: name, triggerDescription: triggerDescription, actionDescription: actionDescription)

        if wantsDailyReminder {
            let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
            if let hour = components.hour, let minute = components.minute {
                routine.reminderHour = hour
                routine.reminderMinute = minute
                let scheduler = NotificationScheduler()
                if await scheduler.requestAuthorization() {
                    scheduler.scheduleDaily(
                        title: routine.name,
                        body: actionDescription.isEmpty ? triggerDescription : actionDescription,
                        hour: hour,
                        minute: minute,
                        identifier: routine.notificationIdentifier
                    )
                }
            }
        }

        modelContext.insert(routine)
        dismiss()
    }
}
