import SwiftUI

/// Spacing, radius, and layout constants. Generous negative space is a brand
/// requirement (docs/ARCHITECTURE.md § Design language) — resist the urge to
/// tighten these to fit more on screen.
public enum Metrics {
    public static let spacingXS: CGFloat = 4
    public static let spacingS: CGFloat = 8
    public static let spacingM: CGFloat = 16
    public static let spacingL: CGFloat = 24
    public static let spacingXL: CGFloat = 32
    public static let spacingXXL: CGFloat = 48

    public static let cardCornerRadius: CGFloat = 20
    public static let controlCornerRadius: CGFloat = 14
    public static let sheetCornerRadius: CGFloat = 28

    public static let screenPadding: CGFloat = 20
    public static let cardPadding: CGFloat = 18

    public static let minTapTarget: CGFloat = 44
}

public enum Motion {
    /// The default spring for state changes: card focus, list reordering,
    /// an insight appearing. Calm, not bouncy.
    public static let standard = Animation.spring(response: 0.42, dampingFraction: 0.86)
    /// Faster spring for small, frequent feedback (checkbox, toggle).
    public static let quick = Animation.spring(response: 0.28, dampingFraction: 0.82)
    /// An Aeria insight or suggestion arriving — should feel like it emerges,
    /// not pop. See master prompt § Motion.
    public static let emerge = Animation.spring(response: 0.55, dampingFraction: 0.9)
}
