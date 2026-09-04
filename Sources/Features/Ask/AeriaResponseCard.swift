import SwiftUI

/// Renders a structured `AeriaResponse` — master prompt § 66: "This turns
/// AI into a usable interface," not a chat transcript. Headline first,
/// optional supporting detail, optional previewable action.
struct AeriaResponseCard: View {
    let response: AeriaResponse
    var onConfirmAction: (AeriaSuggestedAction) -> Void = { _ in }
    var onDismissAction: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.spacingM) {
            SurfaceCard(isElevated: true) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(response.headline)
                        .font(AeriaFont.title)
                        .foregroundStyle(Palette.textPrimary)
                    if let detail = response.detail {
                        Text(detail)
                            .font(AeriaFont.body)
                            .foregroundStyle(Palette.textSecondary)
                    }
                    if response.confidence != .confirmed {
                        ConfidenceBadge(confidence: response.confidence)
                    }
                }
            }

            if let action = response.suggestedAction {
                ActionPreviewCard(
                    title: action.title,
                    detailLine: action.proposedDate.map { $0.formatted(date: .abbreviated, time: .shortened) },
                    confirmLabel: confirmLabel(for: action.kind),
                    onConfirm: { onConfirmAction(action) },
                    onDismiss: onDismissAction
                )
            }
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
        .animation(Motion.emerge, value: response.headline)
    }

    private func confirmLabel(for kind: AeriaActionKind) -> String {
        switch kind {
        case .createReminder: return "Add Reminder"
        case .createEvent: return "Add to Calendar"
        case .createTask: return "Add"
        case .none: return "Save"
        }
    }
}
