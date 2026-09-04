import SwiftUI
import WidgetKit

/// Master prompt § 40: small/medium/large widgets that "update
/// intelligently." One adaptive widget rather than three separate
/// `WidgetConfiguration`s — the layout switches on `widgetFamily`, all fed
/// from the same `TodaySnapshot` the phone last published (see
/// `Sources/Shared/TodaySnapshot.swift`). This extension never touches
/// SwiftData or EventKit itself.
@main
struct AeriaWidgetsBundle: WidgetBundle {
    var body: some Widget {
        AeriaTodayWidget()
        TravelLiveActivityWidget()
    }
}

struct AeriaTodayEntry: TimelineEntry {
    let date: Date
    let snapshot: TodaySnapshot
}

struct AeriaTodayTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> AeriaTodayEntry {
        AeriaTodayEntry(date: .now, snapshot: .empty)
    }

    func getSnapshot(in context: Context, completion: @escaping (AeriaTodayEntry) -> Void) {
        completion(AeriaTodayEntry(date: .now, snapshot: SharedStorage.readSnapshot()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AeriaTodayEntry>) -> Void) {
        let entry = AeriaTodayEntry(date: .now, snapshot: SharedStorage.readSnapshot())
        // The phone republishes the snapshot every time Today loads, which
        // is far more often than this. This 30-minute cadence just makes
        // sure the widget doesn't go stale if the app hasn't been opened —
        // WidgetKit budgets refreshes across all installed widgets, so
        // there's no value in asking for tighter than that.
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 30, to: .now)
            ?? Date().addingTimeInterval(1800)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }
}

struct AeriaTodayWidget: Widget {
    let kind = "AeriaTodayWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AeriaTodayTimelineProvider()) { entry in
            AeriaTodayWidgetView(entry: entry)
                .containerBackground(Palette.canvas, for: .widget)
        }
        .configurationDisplayName("Aeria Today")
        .description("What's next, and what's worth knowing.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct AeriaTodayWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: AeriaTodayEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(snapshot: entry.snapshot)
        case .systemMedium:
            MediumWidgetView(snapshot: entry.snapshot)
        default:
            LargeWidgetView(snapshot: entry.snapshot)
        }
    }
}
