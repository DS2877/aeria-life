import SwiftData
import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @StateObject private var viewModel = TodayViewModel()
    @Binding var isShowingSettings: Bool

    @Query(filter: #Predicate<Place> { !$0.isArchived }) private var places: [Place]
    @Query(filter: #Predicate<Commitment> { !$0.isArchived }) private var commitments: [Commitment]
    @Query(filter: #Predicate<DocumentRecord> { !$0.isArchived }) private var documents: [DocumentRecord]
    @Query(filter: #Predicate<PaymentItem> { !$0.isArchived }) private var payments: [PaymentItem]
    @Query private var notes: [NoteItem]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Metrics.spacingXL) {
                GreetingHeader(
                    greeting: LifeBriefGenerator.greeting(),
                    date: .now,
                    weather: viewModel.weather
                )

                ScheduleTimeline(
                    events: viewModel.todaysEvents,
                    isAuthorized: environment.calendarProvider.isAuthorized
                ) {
                    Task { _ = await environment.calendarProvider.requestAccess(); await reload() }
                }

                WorthKnowingSection(items: worthKnowingItems)

                AeriaObservationCard(headline: aeriaObservation.headline, detail: aeriaObservation.detail)
            }
            .padding(Metrics.screenPadding)
        }
        .refreshable { await reload() }
        .task { await reload() }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isShowingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func reload() async {
        await viewModel.load(environment: environment, knownPlaces: places)
        TravelActivityCoordinator.update(with: viewModel.travelPlan)
        viewModel.publishSnapshot(
            greeting: LifeBriefGenerator.greeting(),
            looseEnds: looseEnds,
            aeriaHeadline: aeriaObservation.headline
        )
    }

    private var looseEnds: [LooseEnd] {
        LooseEndsScanner.scan(
            commitments: commitments,
            documents: documents,
            upcomingPayments: payments,
            unprocessedNotes: notes
        )
    }

    private var conflicts: [SchedulingConflict] {
        SchedulingConflictScanner.findConflicts(in: viewModel.todaysEvents)
    }

    private var worthKnowingItems: [WorthKnowingSection.Item] {
        var items: [WorthKnowingSection.Item] = []

        if let hint = LifeBriefGenerator.worthKnowingLine(weather: viewModel.weather) {
            items.append(.init(id: "weather", symbolName: "cloud.rain.fill", title: hint, detail: nil, tint: Palette.notice))
        }

        for conflict in conflicts.prefix(2) {
            let time = conflict.overlapStart.formatted(date: .omitted, time: .shortened)
            items.append(.init(
                id: conflict.id,
                symbolName: "exclamationmark.triangle.fill",
                title: "\(conflict.firstTitle) and \(conflict.secondTitle) overlap",
                detail: "Both around \(time)",
                tint: Palette.critical
            ))
        }

        for end in looseEnds.prefix(3) {
            items.append(.init(
                id: end.id,
                symbolName: symbolName(for: end.relatedEntityType),
                title: end.summary,
                detail: end.detail,
                tint: Palette.notice
            ))
        }

        return items
    }

    private var aeriaObservation: (headline: String, detail: String?) {
        // A "leave by" that's actually imminent takes precedence over
        // everything else — master prompt § 29's own example ("Leave 10
        // minutes earlier") is exactly this kind of time-sensitive nudge.
        if let plan = viewModel.travelPlan, plan.leaveByDate.timeIntervalSince(.now) < 90 * 60 {
            let time = plan.leaveByDate.formatted(date: .omitted, time: .shortened)
            return ("Leave by \(time) to arrive at \(plan.eventTitle) comfortably.", "\(plan.travelMinutes) min drive.")
        }

        if let conflict = conflicts.first {
            return ("\(conflict.firstTitle) and \(conflict.secondTitle) are scheduled at the same time.", "You'll want to move one of them.")
        }

        let inputs: [PriorityInput] = looseEnds.map { end in
            PriorityInput(
                id: end.id,
                title: end.summary,
                dueDate: nil,
                baseImportance: 0.5,
                isUserPinned: false,
                isRelevantToCurrentLocation: false,
                confidence: .confirmed,
                entityType: end.relatedEntityType
            )
        }

        if let one = PriorityEngine.oneThing(inputs) {
            return (one.title, nil)
        }

        // A real comparison against your own typical pattern, not just a
        // fixed count — master prompt § 28 "unusually busy days."
        if let assessment = viewModel.busyDayAssessment, assessment.isUnusuallyBusy {
            let typical = Int(assessment.typicalCount.rounded())
            return (
                "Today looks busier than usual.",
                "\(assessment.todayCount) events, versus \(typical) on a typical \(weekdayName())."
            )
        }

        let remaining = viewModel.todaysEvents.filter { $0.startDate > .now }.count
        if remaining >= 3 {
            return ("You have a busy day ahead.", "\(remaining) more things on your calendar today.")
        }
        if !looseEnds.isEmpty {
            return ("A couple of things are worth a look when you have a moment.", nil)
        }
        return ("Nothing important needs your attention right now.", nil)
    }

    private func weekdayName(for date: Date = .now) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }

    private func symbolName(for type: LifeEntityType) -> String {
        switch type {
        case .document: return "doc.text"
        case .payment: return "creditcard"
        case .commitment: return "text.bubble"
        case .note: return "tray"
        default: return "sparkle"
        }
    }
}
