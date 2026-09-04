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
    }

    private var looseEnds: [LooseEnd] {
        LooseEndsScanner.scan(
            commitments: commitments,
            documents: documents,
            upcomingPayments: payments,
            unprocessedNotes: notes
        )
    }

    private var worthKnowingItems: [WorthKnowingSection.Item] {
        var items: [WorthKnowingSection.Item] = []

        if let hint = LifeBriefGenerator.worthKnowingLine(weather: viewModel.weather) {
            items.append(.init(id: "weather", symbolName: "cloud.rain.fill", title: hint, detail: nil, tint: Palette.notice))
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

        let remaining = viewModel.todaysEvents.filter { $0.startDate > .now }.count
        if remaining >= 3 {
            return ("You have a busy day ahead.", "\(remaining) more things on your calendar today.")
        }
        if !looseEnds.isEmpty {
            return ("A couple of things are worth a look when you have a moment.", nil)
        }
        return ("Nothing important needs your attention right now.", nil)
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
