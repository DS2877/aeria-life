import SwiftUI

/// Master prompt § 40 large widget: greeting + counts + an insight — a
/// condensed Life Brief (§ 12), not a full Today screen crammed smaller.
struct LargeWidgetView: View {
    let snapshot: TodaySnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(snapshot.greeting)
                .font(AeriaFont.title)
                .foregroundStyle(Palette.textPrimary)

            VStack(alignment: .leading, spacing: 6) {
                statLine("\(snapshot.nextEvents.count)", snapshot.nextEvents.count == 1 ? "event" : "events")
                statLine("\(snapshot.openLooseEndCount)", snapshot.openLooseEndCount == 1 ? "thing worth a look" : "things worth a look")
            }

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkle")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Palette.accent)
                    Text("Aeria")
                        .font(AeriaFont.eyebrow)
                        .tracking(AeriaTextTracking.eyebrow)
                        .foregroundStyle(Palette.textTertiary)
                }
                Text(snapshot.aeriaHeadline)
                    .font(AeriaFont.subheadline)
                    .foregroundStyle(Palette.textPrimary)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func statLine(_ number: String, _ label: String) -> some View {
        HStack(spacing: 6) {
            Text(number)
                .font(AeriaFont.headline)
                .foregroundStyle(Palette.textPrimary)
            Text(label)
                .font(AeriaFont.subheadline)
                .foregroundStyle(Palette.textSecondary)
        }
    }
}
