import EventKit
import SwiftData
import SwiftUI

/// Master prompt § 34: privacy as a product surface, not a settings page
/// buried behind legal jargon. Shows exactly what's granted, where data
/// lives, and offers a real, complete delete.
struct PrivacyCenterView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @Environment(\.modelContext) private var modelContext
    @State private var isConfirmingDeleteAll = false

    var body: some View {
        List {
            Section {
                NavigationLink {
                    WhatAeriaKnowsView()
                } label: {
                    Label("What Aeria Knows", systemImage: "brain")
                }
            }

            Section("What Aeria can access") {
                accessRow(
                    "Calendar",
                    symbol: "calendar",
                    isGranted: EKEventStore.authorizationStatus(for: .event) == .fullAccess
                )
                accessRow(
                    "Reminders",
                    symbol: "checklist",
                    isGranted: EKEventStore.authorizationStatus(for: .reminder) == .fullAccess
                )
                accessRow(
                    "Location",
                    symbol: "location",
                    isGranted: environment.locationProvider.authorizationStatus == .authorizedWhenInUse
                        || environment.locationProvider.authorizationStatus == .authorizedAlways
                )
            }

            Section("Where your data lives") {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Stored only on this device", systemImage: "iphone")
                    Text("Aeria hasn't turned on iCloud sync yet — everything you see is local to this iPhone. See docs/ARCHITECTURE.md if you're setting this up.")
                        .font(AeriaFont.caption)
                        .foregroundStyle(Palette.textSecondary)
                }
                .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 4) {
                    Label("Processed on this device", systemImage: "cpu")
                    Text("Document scanning and Ask Aeria's understanding both run on-device — nothing is sent to a server.")
                        .font(AeriaFont.caption)
                        .foregroundStyle(Palette.textSecondary)
                }
                .padding(.vertical, 4)
            }

            Section {
                Button(role: .destructive) {
                    isConfirmingDeleteAll = true
                } label: {
                    Label("Delete everything", systemImage: "trash")
                }
            }
        }
        .navigationTitle("Privacy Center")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "Delete everything Aeria has stored?",
            isPresented: $isConfirmingDeleteAll,
            titleVisibility: .visible
        ) {
            Button("Delete Everything", role: .destructive, action: deleteEverything)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes every memory, document, and record Aeria has stored on this device. It can't be undone.")
        }
    }

    private func accessRow(_ title: String, symbol: String, isGranted: Bool) -> some View {
        HStack {
            Label(title, systemImage: symbol)
            Spacer()
            Text(isGranted ? "Granted" : "Not granted")
                .font(AeriaFont.caption)
                .foregroundStyle(isGranted ? Palette.positive : Palette.textTertiary)
        }
    }

    private func deleteEverything() {
        // Explicit per-type deletes — every entity in PersistenceController's
        // schema, listed once here rather than iterated reflectively.
        deleteAll(Person.self)
        deleteAll(Organization.self)
        deleteAll(Place.self)
        deleteAll(TaskItem.self)
        deleteAll(Commitment.self)
        deleteAll(DocumentRecord.self)
        deleteAll(Asset.self)
        deleteAll(Subscription.self)
        deleteAll(PaymentItem.self)
        deleteAll(Goal.self)
        deleteAll(Habit.self)
        deleteAll(Moment.self)
        deleteAll(NoteItem.self)
        deleteAll(Routine.self)
        deleteAll(MemoryFact.self)
        deleteAll(LifeRelationship.self)
        try? FileManager.default.removeItem(at: VaultStorage.directoryURL)
    }

    /// Fetch-then-delete rather than the newer bulk `delete(model:)` API —
    /// this only needs guarantees SwiftData has had since iOS 17.0, our
    /// deployment target.
    private func deleteAll<T: PersistentModel>(_ type: T.Type) {
        guard let items = try? modelContext.fetch(FetchDescriptor<T>()) else { return }
        for item in items { modelContext.delete(item) }
    }
}
