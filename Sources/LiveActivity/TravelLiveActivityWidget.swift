import ActivityKit
import SwiftUI
import WidgetKit

/// Renders `TravelActivityAttributes` on the Lock Screen and in the Dynamic
/// Island. Declared as a `Widget` alongside `AeriaTodayWidget` in the same
/// extension bundle — that's how Live Activities work, even though nothing
/// here is a home-screen widget.
struct TravelLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TravelActivityAttributes.self) { context in
            TravelLiveActivityView(attributes: context.attributes, state: context.state)
                .activityBackgroundTint(Palette.canvas)
                .activitySystemActionForegroundColor(Palette.textPrimary)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "car.fill")
                        .foregroundStyle(Palette.accent)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.leaveByDate, style: .time)
                        .font(.headline)
                        .foregroundStyle(Palette.textPrimary)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Leave for \(context.attributes.eventTitle)")
                        .font(.caption)
                        .foregroundStyle(Palette.textSecondary)
                }
            } compactLeading: {
                Image(systemName: "car.fill")
                    .foregroundStyle(Palette.accent)
            } compactTrailing: {
                Text(context.state.leaveByDate, style: .timer)
                    .monospacedDigit()
                    .frame(width: 40)
            } minimal: {
                Image(systemName: "car.fill")
                    .foregroundStyle(Palette.accent)
            }
        }
    }
}

private struct TravelLiveActivityView: View {
    let attributes: TravelActivityAttributes
    let state: TravelActivityAttributes.ContentState

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Leave for \(attributes.eventTitle)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.textPrimary)
                Text("\(state.minutesRemaining) min drive")
                    .font(.caption)
                    .foregroundStyle(Palette.textSecondary)
            }
            Spacer()
            Text(state.leaveByDate, style: .time)
                .font(.title2.weight(.semibold))
                .foregroundStyle(Palette.accent)
        }
        .padding()
    }
}
