import SwiftData
import SwiftUI

struct DecisionsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<DecisionRecord> { !$0.isArchived }, sort: \DecisionRecord.createdAt, order: .reverse)
    private var decisions: [DecisionRecord]
    @State private var isPresentingAdd = false

    var body: some View {
        Group {
            if decisions.isEmpty {
                EmptyStateView(
                    symbolName: "arrow.left.arrow.right",
                    title: "No decisions yet",
                    message: "Compare two options — buy or lease, this job or that one — and Aeria will lay out the cost side by side."
                )
                .padding(.top, Metrics.spacingXXL)
            } else {
                List {
                    ForEach(decisions) { decision in
                        NavigationLink {
                            DecisionDetailView(decision: decision)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(decision.title).foregroundStyle(Palette.textPrimary)
                                Text("\(decision.options.count) option\(decision.options.count == 1 ? "" : "s")")
                                    .font(AeriaFont.caption)
                                    .foregroundStyle(Palette.textSecondary)
                            }
                        }
                        .listRowBackground(Palette.canvas)
                    }
                    .onDelete { offsets in
                        for index in offsets { decisions[index].isArchived = true }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Decisions")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { isPresentingAdd = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $isPresentingAdd) {
            AddDecisionSheet()
        }
    }
}

private struct AddDecisionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var title = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("What are you deciding?", text: $title)
            }
            .navigationTitle("New Decision")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        modelContext.insert(DecisionRecord(title: title))
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
