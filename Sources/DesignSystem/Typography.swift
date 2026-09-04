import SwiftUI

/// Type ramp built on system typography (SF Pro via Dynamic Type). Hierarchy
/// does the visual work here — see docs/ARCHITECTURE.md § Design language —
/// so prefer reaching for a token below over hand-tuning a `.font(.system(...))`
/// at a call site.
public enum AeriaFont {
    /// The one big number/word on a screen — a greeting, a countdown.
    public static let display = Font.system(.largeTitle, design: .rounded, weight: .semibold)
    public static let title = Font.system(.title2, design: .default, weight: .semibold)
    public static let headline = Font.system(.headline, design: .default, weight: .semibold)
    public static let body = Font.system(.body, design: .default, weight: .regular)
    public static let bodyEmphasized = Font.system(.body, design: .default, weight: .medium)
    public static let subheadline = Font.system(.subheadline, design: .default, weight: .regular)
    /// Metadata: timestamps, source attribution, confidence footnotes.
    public static let caption = Font.system(.caption, design: .default, weight: .regular)
    public static let captionEmphasized = Font.system(.caption, design: .default, weight: .semibold)
    /// Section eyebrows ("WORTH KNOWING", "TODAY") — tracked, quiet, small.
    public static let eyebrow = Font.system(.caption2, design: .default, weight: .semibold)
}

public enum AeriaTextTracking {
    public static let eyebrow: CGFloat = 1.2
}
