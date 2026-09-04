import SwiftUI

/// One line in "Worth knowing", Loose Ends, or a Life Brief — an icon, a
/// calm statement, optional detail, and an optional "Handle this" action
/// (master prompt § 31). This is the single most-reused row in the app;
/// every insight-shaped surface should use it rather than a bespoke row.
struct InsightRow: View {
    let symbolName: String
    let title: String
    var detail: String?
    var confidence: ConfidenceLevel = .confirmed
    var tint: Color = Palette.textSecondary
    var onHandle: (() -> Void)?

    var body: some View {
        HStack(alignment: .top, spacing: Metrics.spacingM) {
            Image(systemName: symbolName)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(tint)
                .frame(width: 22)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AeriaFont.body)
                    .foregroundStyle(Palette.textPrimary)
                if let detail {
                    Text(detail)
                        .font(AeriaFont.subheadline)
                        .foregroundStyle(Palette.textSecondary)
                }
                if confidence != .confirmed {
                    ConfidenceBadge(confidence: confidence)
                }
            }

            Spacer(minLength: 0)

            if let onHandle {
                Button("Handle this", action: onHandle)
                    .font(AeriaFont.captionEmphasized)
                    .buttonStyle(.borderless)
                    .foregroundStyle(Palette.accent)
            }
        }
    }
}
