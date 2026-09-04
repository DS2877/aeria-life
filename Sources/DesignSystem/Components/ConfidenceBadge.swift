import SwiftUI

/// Renders the confidence signal master prompt § 55–57 requires everywhere
/// an AI-derived fact appears. Confirmed facts render nothing — a hedge on
/// a plain fact would itself erode trust.
struct ConfidenceBadge: View {
    let confidence: ConfidenceLevel

    var body: some View {
        switch confidence {
        case .confirmed:
            EmptyView()
        case .high:
            label("Aeria's best guess", color: Palette.textSecondary)
        case .low:
            label("Needs your confirmation", color: Palette.notice)
        }
    }

    private func label(_ text: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "sparkle")
                .font(.system(size: 9, weight: .semibold))
            Text(text)
        }
        .font(AeriaFont.caption)
        .foregroundStyle(color)
    }
}

/// "Based on N sources" drill-in — master prompt § 56 AI Source
/// Transparency. Tapping is wired up by the caller (usually opens a sheet
/// listing the source records).
struct SourceAttributionLabel: View {
    let sourceCount: Int
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            Text(sourceCount == 1 ? "Based on 1 source" : "Based on \(sourceCount) sources")
                .font(AeriaFont.caption)
                .foregroundStyle(Palette.textTertiary)
                .underline()
        }
        .buttonStyle(.plain)
    }
}
