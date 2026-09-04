import SwiftUI

/// A minimal "pick one of these" sheet, generic over any `Identifiable`
/// item. Used wherever the user links one existing record to another (a
/// task or document into a Moment) rather than duplicating a picker per
/// entity type.
struct EntityPickerSheet<Item: Identifiable>: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let items: [Item]
    let label: (Item) -> String
    let onPick: (Item) -> Void

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    EmptyStateView(symbolName: "tray", title: "Nothing to link", message: nil)
                } else {
                    List(items) { item in
                        Button(label(item)) {
                            onPick(item)
                            dismiss()
                        }
                        .foregroundStyle(Palette.textPrimary)
                        .listRowBackground(Palette.canvas)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
        }
    }
}
