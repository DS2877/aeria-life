import SwiftUI

/// Master prompt § 76: "What should I do with this?" — a brief look at
/// what was captured before it's queued, never a silent save.
struct ShareReviewView: View {
    @State private var text: String
    let hasImage: Bool
    var onSave: (String) -> Void
    var onCancel: () -> Void

    init(initialText: String, hasImage: Bool, onSave: @escaping (String) -> Void, onCancel: @escaping () -> Void) {
        _text = State(initialValue: initialText)
        self.hasImage = hasImage
        self.onSave = onSave
        self.onCancel = onCancel
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("What Aeria captured") {
                    TextEditor(text: $text)
                        .frame(minHeight: 140)
                    if hasImage {
                        Label("Image attached", systemImage: "photo")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Save to Aeria")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save to Inbox") { onSave(text) }
                        .fontWeight(.semibold)
                        .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !hasImage)
                }
            }
        }
    }
}
