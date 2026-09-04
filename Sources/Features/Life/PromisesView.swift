import SwiftData
import SwiftUI

/// Master prompt § 72 "Promises" — commitments the user made, elevated to
/// their own surface rather than only appearing inside Loose Ends. "Handle
/// it" (§ 31) offers the two things Aeria can actually do here: mark it
/// kept, or turn it into a reminder so it doesn't rely on memory alone.
struct PromisesView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @Query(filter: #Predicate<Commitment> { !$0.isArchived }, sort: \Commitment.createdAt, order: .reverse)
    private var commitments: [Commitment]
    @State private var handlingCommitment: Commitment?

    private var open: [Commitment] { commitments.filter { !$0.isFulfilled } }
    private var kept: [Commitment] { commitments.filter(\.isFulfilled) }

    var body: some View {
        Group {
            if commitments.isEmpty {
                EmptyStateView(
                    symbolName: "text.bubble",
                    title: "No promises tracked",
                    message: "When you tell Aeria you'll do something — \"I'll send Anna the document\" — it shows up here."
                )
                .padding(.top, Metrics.spacingXXL)
            } else {
                List {
                    if !open.isEmpty {
                        Section("Open") {
                            ForEach(open) { commitment in
                                row(commitment)
                            }
                        }
                        .listRowBackground(Palette.canvas)
                    }
                    if !kept.isEmpty {
                        Section("Kept") {
                            ForEach(kept) { commitment in
                                row(commitment)
                            }
                        }
                        .listRowBackground(Palette.canvas)
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Promises")
        .confirmationDialog(
            "Handle this promise",
            isPresented: Binding(get: { handlingCommitment != nil }, set: { if !$0 { handlingCommitment = nil } }),
            titleVisibility: .visible
        ) {
            if let commitment = handlingCommitment {
                Button("Mark as kept") {
                    commitment.isFulfilled = true
                    commitment.fulfilledAt = .now
                }
                Button("Remind me about this") {
                    try? environment.reminderProvider.createReminder(title: commitment.text, dueDate: commitment.resolvedDueDate)
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private func row(_ commitment: Commitment) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(commitment.text)
                    .foregroundStyle(commitment.isFulfilled ? Palette.textTertiary : Palette.textPrimary)
                    .strikethrough(commitment.isFulfilled)
                if !commitment.dueHint.isEmpty {
                    Text(commitment.dueHint)
                        .font(AeriaFont.caption)
                        .foregroundStyle(Palette.textSecondary)
                }
            }
            Spacer()
            if !commitment.isFulfilled {
                Button("Handle this") { handlingCommitment = commitment }
                    .font(AeriaFont.captionEmphasized)
                    .buttonStyle(.borderless)
                    .foregroundStyle(Palette.accent)
            }
        }
    }
}
