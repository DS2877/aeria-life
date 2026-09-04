import SwiftUI

struct AeriaPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AeriaFont.bodyEmphasized)
            .foregroundStyle(Palette.canvas)
            .padding(.horizontal, Metrics.spacingL)
            .padding(.vertical, Metrics.spacingS + 2)
            .frame(minHeight: Metrics.minTapTarget - 8)
            .background(Palette.accent)
            .clipShape(RoundedRectangle(cornerRadius: Metrics.controlCornerRadius, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(Motion.quick, value: configuration.isPressed)
    }
}

struct AeriaSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AeriaFont.bodyEmphasized)
            .foregroundStyle(Palette.textPrimary)
            .padding(.horizontal, Metrics.spacingL)
            .padding(.vertical, Metrics.spacingS + 2)
            .frame(minHeight: Metrics.minTapTarget - 8)
            .background(Palette.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: Metrics.controlCornerRadius, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(Motion.quick, value: configuration.isPressed)
    }
}
