import SwiftUI

/// The "Aeria" card at the bottom of Today — master prompt § 6 example
/// ("You have a busy afternoon...") and § 7's explicit permission to say
/// nothing: "Nothing important needs your attention right now" is a valid,
/// intended result, not a failure state.
struct AeriaObservationCard: View {
    let headline: String
    let detail: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.spacingM) {
            SectionHeader(title: "Aeria")
            SurfaceCard(isElevated: true) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkle")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Palette.accent)
                        Text(headline)
                            .font(AeriaFont.bodyEmphasized)
                            .foregroundStyle(Palette.textPrimary)
                    }
                    if let detail {
                        Text(detail)
                            .font(AeriaFont.subheadline)
                            .foregroundStyle(Palette.textSecondary)
                    }
                }
            }
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
        .animation(Motion.emerge, value: headline)
    }
}
