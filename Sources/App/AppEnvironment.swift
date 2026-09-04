import Foundation
import SwiftData

/// The app's dependency container. One instance, created once in
/// `AeriaApp`, threaded through the environment. Kept as concrete stored
/// providers (not a service-locator lookup) so every dependency a view
/// needs is visible right here — see docs/ARCHITECTURE.md § Module map.
@MainActor
final class AppEnvironment: ObservableObject {
    let modelContainer: ModelContainer
    let calendarProvider = CalendarContextProvider()
    let reminderProvider = ReminderContextProvider()
    let locationProvider = LocationContextProvider()
    let weatherProvider: WeatherContextProviding
    let intelligenceProvider: AeriaIntelligenceProviding
    let notificationScheduler = NotificationScheduler()

    /// Manual Life Mode override — master prompt § 14: inferred by default,
    /// but the user can always pin it, and it never traps them.
    @Published var manualLifeModeOverride: LifeMode?

    init(
        modelContainer: ModelContainer = PersistenceController.shared,
        weatherProvider: WeatherContextProviding = UnavailableWeatherProvider(),
        intelligenceProvider: AeriaIntelligenceProviding = RuleBasedIntelligenceProvider()
    ) {
        // TEMPORARY diagnostic — see AeriaApp.init()'s matching note.
        print("AppEnvironment.init(): modelContainer ready, wiring providers")
        self.modelContainer = modelContainer
        self.weatherProvider = weatherProvider
        self.intelligenceProvider = intelligenceProvider
        print("AppEnvironment.init(): done")
    }

    var mainContext: ModelContext { modelContainer.mainContext }

    func makeMemoryStore() -> MemoryStore {
        MemoryStore(context: mainContext)
    }
}
