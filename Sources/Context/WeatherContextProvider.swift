import CoreLocation
import Foundation

struct WeatherSnapshot: Equatable {
    let temperatureCelsius: Double
    let conditionDescription: String
    let symbolName: String
    /// A short natural-language heads-up worth surfacing on Today, e.g.
    /// "Rain begins around 16:40" — nil when nothing is notable.
    let notableChangeHint: String?
}

protocol WeatherContextProviding {
    func currentConditions(at location: CLLocation) async -> WeatherSnapshot?
}

/// Default binding until WeatherKit is provisioned (see below). Returns nil
/// rather than fabricating a forecast — master prompt § 91 "never fabricate
/// personal facts"; Today simply omits the weather chip (§ 53 empty states).
struct UnavailableWeatherProvider: WeatherContextProviding {
    func currentConditions(at location: CLLocation) async -> WeatherSnapshot? { nil }
}

#if canImport(WeatherKit)
import WeatherKit

/// Real WeatherKit-backed provider. Not wired up as the default binding yet
/// — see docs/ARCHITECTURE.md § Context Engine for the one-time setup
/// (Apple Developer portal capability + Xcode capability) this needs before
/// switching `AppEnvironment` over to it. Until then `UnavailableWeatherProvider`
/// keeps the app buildable and signable with zero extra configuration.
@available(iOS 16.0, *)
struct WeatherKitProvider: WeatherContextProviding {
    private let service = WeatherService.shared

    func currentConditions(at location: CLLocation) async -> WeatherSnapshot? {
        do {
            let weather = try await service.weather(for: location)
            let current = weather.currentWeather
            var hint: String?
            if let firstRain = weather.hourlyForecast.forecast
                .first(where: { $0.date > .now && $0.precipitationChance > 0.4 }) {
                let formatter = DateFormatter()
                formatter.timeStyle = .short
                hint = "Rain becomes likely around \(formatter.string(from: firstRain.date))."
            }
            return WeatherSnapshot(
                temperatureCelsius: current.temperature.converted(to: .celsius).value,
                conditionDescription: current.condition.description,
                symbolName: current.symbolName,
                notableChangeHint: hint
            )
        } catch {
            return nil
        }
    }
}
#endif
