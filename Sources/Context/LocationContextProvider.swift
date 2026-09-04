import CoreLocation
import Foundation

/// Provides current location for context (master prompt § 13) — travel time,
/// local weather, and matching against the user's own saved `Place`s to
/// infer Life Mode. Deliberately coarse: Aeria does not need precise
/// tracking or geofencing for the MVP, just "am I near home or work."
@MainActor
final class LocationContextProvider: NSObject, ObservableObject {
    private let manager = CLLocationManager()

    @Published private(set) var authorizationStatus: CLAuthorizationStatus
    @Published private(set) var currentLocation: CLLocation?

    override init() {
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.delegate = self
    }

    func requestAccess() {
        manager.requestWhenInUseAuthorization()
    }

    func refreshLocation() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else { return }
        manager.requestLocation()
    }

    /// The closest saved `Place` within `thresholdMeters`, or nil if the
    /// user isn't near anywhere Aeria knows about.
    func nearestKnownPlace(among places: [Place], thresholdMeters: CLLocationDistance = 150) -> Place? {
        guard let currentLocation else { return nil }
        let candidates: [(Place, CLLocationDistance)] = places.compactMap { place in
            guard let latitude = place.latitude, let longitude = place.longitude else { return nil }
            let location = CLLocation(latitude: latitude, longitude: longitude)
            let distance = currentLocation.distance(from: location)
            return distance <= thresholdMeters ? (place, distance) : nil
        }
        return candidates.min { $0.1 < $1.1 }?.0
    }
}

extension LocationContextProvider: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus
            refreshLocation()
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            currentLocation = location
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Silent by design — location is enrichment, never a blocking
        // requirement (master prompt § 60–61 offline/degraded behaviour).
    }
}
