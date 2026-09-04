import SwiftUI

/// One contextual permission ask — master prompt § 52: "never request
/// permission without explaining why," and each permission gets its own
/// moment rather than a wall of system prompts.
struct PermissionStepView: View {
    let symbolName: String
    let title: String
    let explanation: String
    let requestLabel: String
    var onRequest: () async -> Void
    var onSkip: () -> Void
    var onContinue: () -> Void

    @State private var hasRequested = false

    var body: some View {
        VStack(spacing: Metrics.spacingXL) {
            Spacer()
            Image(systemName: symbolName)
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(Palette.accent)
            VStack(spacing: Metrics.spacingS) {
                Text(title)
                    .font(AeriaFont.title)
                    .foregroundStyle(Palette.textPrimary)
                    .multilineTextAlignment(.center)
                Text(explanation)
                    .font(AeriaFont.body)
                    .foregroundStyle(Palette.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Metrics.spacingL)
            }
            Spacer()

            VStack(spacing: Metrics.spacingS) {
                Button(hasRequested ? "Continue" : requestLabel) {
                    if hasRequested {
                        onContinue()
                    } else {
                        hasRequested = true
                        Task {
                            await onRequest()
                            onContinue()
                        }
                    }
                }
                .buttonStyle(AeriaPrimaryButtonStyle())
                .frame(maxWidth: .infinity)

                if !hasRequested {
                    Button("Not now", action: onSkip)
                        .buttonStyle(.plain)
                        .font(AeriaFont.subheadline)
                        .foregroundStyle(Palette.textSecondary)
                }
            }
        }
        .padding(Metrics.spacingXL)
    }
}
