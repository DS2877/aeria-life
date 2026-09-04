import SwiftUI

/// Master prompt § 30, § 67: every Aeria-initiated action must be
/// previewable and require explicit confirmation before anything is
/// created or sent. This is the one and only way Aeria proposes an action —
/// there is no code path that creates a reminder/event/etc. without a user
/// tapping "Add" on one of these.
struct ActionPreviewCard: View {
    let title: String
    let detailLine: String?
    let confirmLabel: String
    var onConfirm: () -> Void
    var onDismiss: () -> Void

    var body: some View {
        SurfaceCard(isElevated: true) {
            VStack(alignment: .leading, spacing: Metrics.spacingM) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(AeriaFont.bodyEmphasized)
                        .foregroundStyle(Palette.textPrimary)
                    if let detailLine {
                        Text(detailLine)
                            .font(AeriaFont.subheadline)
                            .foregroundStyle(Palette.textSecondary)
                    }
                }

                HStack(spacing: Metrics.spacingS) {
                    Button(confirmLabel, action: onConfirm)
                        .buttonStyle(AeriaPrimaryButtonStyle())
                    Button("Not now", action: onDismiss)
                        .buttonStyle(AeriaSecondaryButtonStyle())
                }
            }
        }
    }
}
