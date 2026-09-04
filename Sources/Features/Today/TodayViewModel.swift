import Foundation

@MainActor
final class TodayViewModel: ObservableObject {
    @Published private(set) var todaysEvents: [CalendarEvent] = []
    @Published private(set) var openReminders: [LifeReminder] = []
    @Published private(set) var weather: WeatherSnapshot?
    @Published private(set) var currentMode: LifeMode = .home
    @Published private(set) var isLoading = false

    func load(environment: AppEnvironment, knownPlaces: [Place]) async {
        isLoading = true
        defer { isLoading = false }

        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? now

        todaysEvents = environment.calendarProvider.isAuthorized
            ? environment.calendarProvider.events(from: startOfDay, to: endOfDay)
            : []

        openReminders = environment.reminderProvider.isAuthorized
            ? await environment.reminderProvider.fetchIncompleteReminders()
            : []

        environment.locationProvider.refreshLocation()
        let nearestPlace = environment.locationProvider.nearestKnownPlace(among: knownPlaces)
        currentMode = LifeModeEngine.inferMode(
            now: now,
            todaysEvents: todaysEvents,
            nearestPlaceCategory: nearestPlace?.category,
            manualOverride: environment.manualLifeModeOverride
        )

        if let location = environment.locationProvider.currentLocation {
            weather = await environment.weatherProvider.currentConditions(at: location)
        } else {
            weather = nil
        }
    }

    var nextEvent: CalendarEvent? {
        todaysEvents.first { $0.endDate > .now }
    }

    /// Publishes a `TodaySnapshot` for the Widget/Watch surfaces to read.
    /// Called explicitly by `TodayView` after a reload, never from `body` —
    /// this is a side effect (a `UserDefaults` write), not a computation.
    func publishSnapshot(greeting: String, looseEnds: [LooseEnd], aeriaHeadline: String) {
        let events = todaysEvents
            .filter { $0.endDate > .now }
            .prefix(5)
            .map {
                TodaySnapshot.EventSummary(id: $0.id, title: $0.title, startDate: $0.startDate, isAllDay: $0.isAllDay)
            }
        let insights = looseEnds.prefix(3).map { TodaySnapshot.Insight(id: $0.id, title: $0.summary) }

        let snapshot = TodaySnapshot(
            generatedAt: .now,
            greeting: greeting,
            nextEvents: Array(events),
            insights: insights,
            aeriaHeadline: aeriaHeadline,
            openLooseEndCount: looseEnds.count
        )
        SharedStorage.writeSnapshot(snapshot)
        PhoneConnectivityBridge.shared.send(snapshot)
    }
}
