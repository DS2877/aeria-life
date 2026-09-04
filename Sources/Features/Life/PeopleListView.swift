import Contacts
import ContactsUI
import SwiftData
import SwiftUI

/// Master prompt § 71: people, not CRM records. Deliberately thin — name,
/// relationship, birthday, notes — with an optional link to the system
/// Contacts card rather than duplicating contact data.
struct PeopleListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Person.name) private var people: [Person]
    @State private var isPresentingAdd = false

    var body: some View {
        Group {
            if people.isEmpty {
                EmptyStateView(symbolName: "person", title: "No one yet", message: "Add someone Aeria should know about.")
                    .padding(.top, Metrics.spacingXXL)
            } else {
                List {
                    ForEach(people) { person in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(person.name).foregroundStyle(Palette.textPrimary)
                            if !person.relationshipLabel.isEmpty {
                                Text(person.relationshipLabel)
                                    .font(AeriaFont.caption)
                                    .foregroundStyle(Palette.textSecondary)
                            }
                        }
                        .listRowBackground(Palette.canvas)
                    }
                    .onDelete { offsets in
                        for index in offsets { modelContext.delete(people[index]) }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("People")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { isPresentingAdd = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $isPresentingAdd) {
            AddPersonSheet()
        }
    }
}

private struct AddPersonSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var relationshipLabel = ""
    @State private var notes = ""
    @State private var isPickingContact = false
    @State private var linkedContactIdentifier: String?

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                TextField("Relationship (e.g. sister, landlord)", text: $relationshipLabel)
                TextField("Notes", text: $notes, axis: .vertical)

                Section {
                    Button {
                        isPickingContact = true
                    } label: {
                        Label(linkedContactIdentifier == nil ? "Link a Contact" : "Contact linked", systemImage: "person.crop.circle")
                    }
                }
            }
            .navigationTitle("Add Person")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .sheet(isPresented: $isPickingContact) {
                ContactPickerView { contact in
                    linkedContactIdentifier = contact.identifier
                    if name.isEmpty {
                        name = CNContactFormatter.string(from: contact, style: .fullName) ?? name
                    }
                }
            }
        }
    }

    private func save() {
        modelContext.insert(Person(
            name: name,
            relationshipLabel: relationshipLabel,
            notes: notes,
            contactIdentifier: linkedContactIdentifier
        ))
        dismiss()
    }
}

/// Thin bridge to Apple's own contact picker — master prompt § 71: link to
/// Contacts rather than rebuilding it. `CNContactPickerViewController`
/// needs no explicit Contacts permission itself (the system UI runs out of
/// process), only `contactIdentifier` values it returns require permission
/// to resolve later — so this doesn't need `NSContactsUsageDescription` to
/// function, though Aeria declares it anyway for future direct lookups.
struct ContactPickerView: UIViewControllerRepresentable {
    var onPick: (CNContact) -> Void

    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }

    final class Coordinator: NSObject, CNContactPickerDelegate {
        let onPick: (CNContact) -> Void
        init(onPick: @escaping (CNContact) -> Void) { self.onPick = onPick }

        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            onPick(contact)
        }
    }
}
