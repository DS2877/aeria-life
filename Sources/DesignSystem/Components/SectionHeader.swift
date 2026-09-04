import SwiftUI

/// The small tracked-caps eyebrow above a Today section ("WORTH KNOWING").
/// Typography carries the hierarchy here rather than a background/divider
/// (master prompt § 47).
struct SectionHeader: View {
    let title: String
    var trailingAction: (title: String, action: () -> Void)?

    var body: some View {
        HStack {
            Text(title.uppercased())
                .font(AeriaFont.eyebrow)
                .tracking(AeriaTextTracking.eyebrow)
                .foregroundStyle(Palette.textTertiary)
            Spacer()
            if let trailingAction {
                Button(trailingAction.title, action: trailingAction.action)
                    .font(AeriaFont.caption)
                    .foregroundStyle(Palette.accent)
            }
        }
    }
}
