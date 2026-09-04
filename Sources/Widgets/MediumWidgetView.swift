import SwiftUI

/// Master prompt § 40 medium widget: "TODAY" + the next couple of events.
struct MediumWidgetView: View {
    let snapshot: TodaySnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TODAY")
                .font(AeriaFont.eyebrow)
                .tracking(AeriaTextTracking.eyebrow)
                .foregroundStyle(Palette.textTertiary)

            if snapshot.nextEvents.isEmpty {
                Text("Nothing else on your calendar today.")
                    .font(AeriaFont.subheadline)
                    .foregroundStyle(Palette.textSecondary)
            } else {
                ForEach(snapshot.nextEvents.prefix(3)) { event in
                    HStack(spacing: 8) {
                        Text(event.isAllDay ? "All day" : event.startDate.formatted(date: .omitted, time: .shortened))
                            .font(AeriaFont.caption.monospacedDigit())
                            .foregroundStyle(Palette.textSecondary)
                            .frame(width: 52, alignment: .leading)
                        Text(event.title)
                            .font(AeriaFont.subheadline)
                            .foregroundStyle(Palette.textPrimary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer(minLength: 0)

            if let insight = snapshot.insights.first {
                Text(insight.title)
                    .font(AeriaFont.caption)
                    .foregroundStyle(Palette.notice)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
