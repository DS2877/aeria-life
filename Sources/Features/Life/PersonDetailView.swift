import SwiftData
import SwiftUI

/// Master prompt § 72's own example — "You said you'd send Anna the
/// document" — needs a promise actually linked to a person. This view is
/// where `Commitment.toPersonID` (previously set nowhere) gets used.
struct PersonDetailView: View {
    let person: Person

    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Commitment> { !$0.isArchived }) private var allCommitments: [Commitment]
    @State private var isAddingPromise = false

    private var personID: String { person.id.uuidString }
    private var linkedCommitments: [Commitment] {
        allCommitments.filter { $0.toPersonID == personID }
    }

    var body: some View {
        List {
            Section {
                if !person.relationshipLabel.isEmpty {
                    LabeledContent("Relationship", value: person.relationshipLabel)
                }
                if !person.notes.isEmpty {
                    Text(person.notes).foregroundStyle(Palette.textSecondary)
                }
            }
            .listRowBackground(Palette.canvas)

            Section("Promises") {
                if linkedCommitments.isEmpty {
                    Text("Nothing tracked yet").foregroundStyle(Palette.textTertiary)
                } else {
                    ForEach(linkedCommitments) { commitment in
                        HStack {
                            Text(commitment.text)
                                .foregroundStyle(commitment.isFulfilled ? Palette.textTertiary : Palette.textPrimary)
                                .strikethrough(commitment.isFulfilled)
                            Spacer()
                            if !commitment.isFulfilled {
                                Button("Mark kept") {
                                    commitment.isFulfilled = true
                                    commitment.fulfilledAt = .now
                                }
                                .font(AeriaFont.caption)
                                .buttonStyle(.borderless)
                            }
                        }
                    }
                }
                Button("Add a promise") { isAddingPromise = true }
                    .foregroundStyle(Palette.accent)
            }
            .listRowBackground(Palette.canvas)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .navigationTitle(person.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isAddingPromise) {
            AddPromiseForPersonSheet(personID: personID)
        }
    }
}

private struct AddPromiseForPersonSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let personID: String
    @State private var text = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("What did you promise?", text: $text, axis: .vertical)
            }
            .navigationTitle("New Promise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        modelContext.insert(Commitment(text: text, toPersonID: personID, provenance: .userProvided))
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
