import SwiftUI

/// Master prompt § 53: empty states must be useful and mature, never
/// "Nothing here." with excess personality. `symbolName` should almost
/// always be a quiet SF Symbol, not an illustration.
struct EmptyStateView: View {
    let symbolName: String
    let title: String
    let message: String?

    var body: some View {
        VStack(spacing: Metrics.spacingM) {
            Image(systemName: symbolName)
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(Palette.textTertiary)
            Text(title)
                .font(AeriaFont.headline)
                .foregroundStyle(Palette.textPrimary)
            if let message {
                Text(message)
                    .font(AeriaFont.subheadline)
                    .foregroundStyle(Palette.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(Metrics.spacingXL)
        .frame(maxWidth: .infinity)
    }
}
