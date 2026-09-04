import SwiftUI

/// Applies the app-wide background, default text colour, and tint. Put this
/// once near the root — mirrors Aeria+'s AppThemeBackground so the two
/// products share the same base treatment.
struct AppThemeBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Palette.canvas.ignoresSafeArea())
            .foregroundStyle(Palette.textPrimary)
            .tint(Palette.accent)
            .preferredColorScheme(.dark)
    }
}

extension View {
    func appThemeBackground() -> some View { modifier(AppThemeBackground()) }
}

/// The base card surface used everywhere — Today rows, Vault items, Ask
/// Aeria responses. Deliberately restrained: a hairline border and a flat
/// fill, no drop shadow by default (this is a phone held close, not a TV
/// screen at a distance).
struct SurfaceCard<Content: View>: View {
    private let content: Content
    private let isElevated: Bool

    init(isElevated: Bool = false, @ViewBuilder content: () -> Content) {
        self.isElevated = isElevated
        self.content = content()
    }

    var body: some View {
        content
            .padding(Metrics.cardPadding)
            .background(isElevated ? Palette.surfaceElevated : Palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: Metrics.cardCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Metrics.cardCornerRadius, style: .continuous)
                    .strokeBorder(Palette.hairline, lineWidth: 1)
            )
    }
}

/// A translucent floating panel — sheets, overlays, the Ask Aeria input bar.
/// Used sparingly by design (master prompt § 48): "material, not
/// glassmorphism."
struct GlassPanel<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .background(.ultraThinMaterial.opacity(0.9))
            .background(Palette.surfaceGlass)
            .clipShape(RoundedRectangle(cornerRadius: Metrics.sheetCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Metrics.sheetCornerRadius, style: .continuous)
                    .strokeBorder(Palette.hairlineStrong, lineWidth: 1)
            )
    }
}
