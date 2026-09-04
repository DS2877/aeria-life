import SwiftUI

/// Colour tokens shared across Aeria. Aeria is dark-only by product decision
/// (see docs/ARCHITECTURE.md § Design language) — the same cinematic
/// near-black canvas and single accent blue as Aeria+, so the two products
/// read as one company. Values are shared verbatim with Aeria+'s palette;
/// keep them in sync if either brand shifts.
public enum Palette {
    /// App background — near-black.
    public static let canvas = Color(red: 0.031, green: 0.031, blue: 0.039)          // #08080A
    /// Cards and raised surfaces — barely lifted off the canvas.
    public static let surface = Color(red: 0.075, green: 0.078, blue: 0.090)         // #131417
    /// Surface for a nested/second-level card (e.g. a row inside a card).
    public static let surfaceElevated = Color(red: 0.121, green: 0.125, blue: 0.141) // #1F2024
    /// Surface for a floating sheet or overlay panel.
    public static let surfaceGlass = Color(red: 0.121, green: 0.125, blue: 0.141).opacity(0.72)

    // Apple's on-dark label ramp — crisp white down to a quiet tertiary grey.
    public static let textPrimary = Color(red: 0.961, green: 0.961, blue: 0.969)     // #F5F5F7
    public static let textSecondary = Color(red: 0.596, green: 0.596, blue: 0.624)   // #98989F
    public static let textTertiary = Color(red: 0.388, green: 0.388, blue: 0.400)    // #636366

    /// Single accent — the Aeria mark's blue. Used sparingly: the app tint,
    /// primary actions, selected state, progress fills. Also mirrored in
    /// Assets/AccentColor.
    public static let accent = Color(red: 0.231, green: 0.620, blue: 1.0)            // #3B9EFF
    public static let accentSoft = accent.opacity(0.16)

    /// Something needs attention, but calmly — approaching deadlines,
    /// unconfirmed AI extractions. Never used for alarm.
    public static let notice = Color(red: 0.949, green: 0.702, blue: 0.302)          // #F2B34D
    public static let noticeSoft = notice.opacity(0.16)

    /// Confirmed, resolved, on track.
    public static let positive = Color(red: 0.298, green: 0.788, blue: 0.522)        // #4CC985
    public static let positiveSoft = positive.opacity(0.16)

    /// Reserved for genuinely urgent/destructive contexts — used rarely.
    /// Aeria's whole voice is calm; most "worth knowing" items use `notice`.
    public static let critical = Color(red: 0.918, green: 0.263, blue: 0.337)        // #EA4356
    public static let criticalSoft = critical.opacity(0.16)

    public static let hairline = Color.white.opacity(0.06)
    public static let hairlineStrong = Color.white.opacity(0.12)
}
