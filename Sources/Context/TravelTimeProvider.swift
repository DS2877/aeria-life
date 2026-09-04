import CoreLocation
import Foundation
import MapKit

struct TravelPlan {
    let eventTitle: String
    let leaveByDate: Date
    let travelMinutes: Int
}

/// Master prompt § 20, § 29: "Leave at 16:42 to arrive comfortably" — a real
/// MapKit route estimate, not a guess. Only ever produces a plan when Aeria
/// has both a current location and a resolvable destination string; any
/// failure (no location permission, ungeocodable address, no route) simply
/// yields `nil` so this stays a nice-to-have layered on top of Today rather
/// than something the rest of the app depends on.
struct TravelTimeProvider {
    /// Safety margin on top of MapKit's own estimate — "comfortably," not
    /// "exactly on time."
    var bufferMinutes: Int = 10

    func plan(eventTitle: String, eventStart: Date, destinationAddress: String?, from origin: CLLocation) async -> TravelPlan? {
        guard let destinationAddress, !destinationAddress.isEmpty else { return nil }
        guard let destination = await geocode(destinationAddress) else { return nil }

        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: origin.coordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination.coordinate))
        request.transportType = .automobile

        guard let response = try? await MKDirections(request: request).calculate(),
              let travelTime = response.routes.first?.expectedTravelTime else {
            return nil
        }

        let totalSeconds = travelTime + TimeInterval(bufferMinutes * 60)
        return TravelPlan(
            eventTitle: eventTitle,
            leaveByDate: eventStart.addingTimeInterval(-totalSeconds),
            travelMinutes: Int((travelTime / 60).rounded())
        )
    }

    private func geocode(_ address: String) async -> CLLocation? {
        await withCheckedContinuation { (continuation: CheckedContinuation<CLLocation?, Never>) in
            CLGeocoder().geocodeAddressString(address) { placemarks, _ in
                continuation.resume(returning: placemarks?.first?.location)
            }
        }
    }
}
