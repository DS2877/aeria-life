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
}
