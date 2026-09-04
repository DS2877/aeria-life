import SwiftUI

/// The day's events as a quiet time-led list — master prompt § 6. Not a
/// full calendar view; just enough to answer "what do I have today" at a
/// glance.
struct ScheduleTimeline: View {
    let events: [CalendarEvent]
    let isAuthorized: Bool
    var onRequestAccess: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.spacingM) {
            SectionHeader(title: "Today")

            if !isAuthorized {
                connectCalendarPrompt
            } else if events.isEmpty {
                Text("Nothing on your calendar today.")
                    .font(AeriaFont.subheadline)
                    .foregroundStyle(Palette.textSecondary)
            } else {
                SurfaceCard {
                    VStack(alignment: .leading, spacing: Metrics.spacingM) {
                        ForEach(Array(events.enumerated()), id: \.element.id) { index, event in
                            if index > 0 {
                                Divider().overlay(Palette.hairline)
                            }
                            eventRow(event)
                        }
                    }
                }
            }
        }
    }

    private func eventRow(_ event: CalendarEvent) -> some View {
        HStack(alignment: .top, spacing: Metrics.spacingM) {
            Text(event.isAllDay ? "All day" : event.startDate.formatted(date: .omitted, time: .shortened))
                .font(AeriaFont.subheadline.monospacedDigit())
                .foregroundStyle(Palette.textSecondary)
                .frame(width: 64, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(AeriaFont.bodyEmphasized)
                    .foregroundStyle(Palette.textPrimary)
                if let location = event.location, !location.isEmpty {
                    Text(location)
                        .font(AeriaFont.caption)
                        .foregroundStyle(Palette.textTertiary)
                }
            }
            Spacer(minLength: 0)
        }
    }

    private var connectCalendarPrompt: some View {
        SurfaceCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Connect your calendar")
                        .font(AeriaFont.bodyEmphasized)
                        .foregroundStyle(Palette.textPrimary)
                    Text("Aeria builds Today from what's already on your calendar.")
                        .font(AeriaFont.caption)
                        .foregroundStyle(Palette.textSecondary)
                }
                Spacer()
                Button("Connect", action: onRequestAccess)
                    .buttonStyle(AeriaSecondaryButtonStyle())
            }
        }
    }
}
