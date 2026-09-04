import SwiftUI

/// Master prompt § 51 "The Magic Moment" — with one important departure
/// from the literal example: a brand-new install has no history yet, so
/// this shows whatever is *actually* true right now (today's real event
/// count pulled live from the user's calendar is already the magic) rather
/// than a fabricated "2 deadlines, 1 trip, 1 insurance renewal." Master
/// prompt § 91: never invent a fact, even for a good first impression.
struct MagicMomentView: View {
    @EnvironmentObject private var environment: AppEnvironment
    let onFinish: () -> Void

    @State private var todayEventCount = 0
    @State private var upcomingWeekEventCount = 0
    @State private var openReminderCount = 0
    @State private var hasLoaded = false

    var body: some View {
        VStack(spacing: Metrics.spacingXL) {
            Spacer()

            if !hasLoaded {
                ProgressView().tint(Palette.accent)
            } else {
                VStack(spacing: Metrics.spacingS) {
                    Text("Your life")
                        .font(AeriaFont.eyebrow)
                        .tracking(AeriaTextTracking.eyebrow)
                        .foregroundStyle(Palette.textTertiary)
                    Text(headline)
                        .font(AeriaFont.title)
                        .foregroundStyle(Palette.textPrimary)
                        .multilineTextAlignment(.center)
                }

                if !summaryLines.isEmpty {
                    SurfaceCard(isElevated: true) {
                        VStack(alignment: .leading, spacing: Metrics.spacingM) {
                            ForEach(Array(summaryLines.enumerated()), id: \.offset) { index, line in
                                if index > 0 { Divider().overlay(Palette.hairline) }
                                HStack {
                                    Text(line.label)
                                        .font(AeriaFont.body)
                                        .foregroundStyle(Palette.textSecondary)
                                    Spacer()
                                    Text(line.value)
                                        .font(AeriaFont.headline)
                                        .foregroundStyle(Palette.textPrimary)
                                }
                            }
                        }
                    }
                }
            }

            Spacer()

            Button("Go to Today") { onFinish() }
                .buttonStyle(AeriaPrimaryButtonStyle())
                .frame(maxWidth: .infinity)
                .disabled(!hasLoaded)
        }
        .padding(Metrics.spacingXL)
        .task { await load() }
    }

    private var headline: String {
        if todayEventCount + upcomingWeekEventCount + openReminderCount == 0 {
            return "Your life is still loading in."
        }
        return "Aeria found \(todayEventCount + openReminderCount) thing\(todayEventCount + openReminderCount == 1 ? "" : "s") worth knowing today."
    }

    private var summaryLines: [(label: String, value: String)] {
        var lines: [(String, String)] = []
        if environment.calendarProvider.isAuthorized {
            lines.append(("Today", "\(todayEventCount) event\(todayEventCount == 1 ? "" : "s")"))
            lines.append(("This week", "\(upcomingWeekEventCount) event\(upcomingWeekEventCount == 1 ? "" : "s")"))
        }
        if environment.reminderProvider.isAuthorized {
            lines.append(("Open reminders", "\(openReminderCount)"))
        }
        return lines
    }

    private func load() async {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? now
        let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfDay) ?? now

        if environment.calendarProvider.isAuthorized {
            todayEventCount = environment.calendarProvider.events(from: startOfDay, to: endOfDay).count
            upcomingWeekEventCount = environment.calendarProvider.events(from: startOfDay, to: endOfWeek).count
        }
        if environment.reminderProvider.isAuthorized {
            openReminderCount = await environment.reminderProvider.fetchIncompleteReminders().count
        }
        hasLoaded = true
    }
}
