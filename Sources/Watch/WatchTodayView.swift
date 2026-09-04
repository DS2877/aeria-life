import SwiftUI

struct WatchTodayView: View {
    @EnvironmentObject private var connectivity: WatchConnectivityReceiver

    private var snapshot: TodaySnapshot { connectivity.snapshot }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text(snapshot.greeting)
                    .font(.headline)
                    .foregroundStyle(.white)

                if let next = snapshot.nextEvents.first {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("NEXT")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.secondary)
                        Text(next.title)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                        if !next.isAllDay {
                            Text(next.startDate, style: .time)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else if snapshot.generatedAt == .distantPast {
                    Text("Open Aeria on your iPhone to sync.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Nothing else on your calendar.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if !snapshot.insights.isEmpty {
                    Divider()
                    ForEach(snapshot.insights.prefix(2)) { insight in
                        Text(insight.title)
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
        }
        .navigationTitle("Aeria")
    }
}
