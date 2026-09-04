import Foundation
import WatchConnectivity

/// Pushes the latest `TodaySnapshot` to the paired Apple Watch. Kept
/// separate from `SharedStorage` (which the Widget extension reads) because
/// `WCSession` is meant to be hosted by a long-lived app, not an extension —
/// Apple's guidance is explicit that app extensions are poor `WCSession`
/// hosts given their transient lifecycle. The widget and the watch both end
/// up with the same `TodaySnapshot`, just delivered two different ways.
@MainActor
final class PhoneConnectivityBridge: NSObject {
    static let shared = PhoneConnectivityBridge()

    private override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func send(_ snapshot: TodaySnapshot) {
        guard WCSession.isSupported(), WCSession.default.activationState == .activated else { return }
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        // `updateApplicationContext` (not `sendMessage`) — it's fire-and-forget,
        // doesn't need the watch app to be foreground/reachable right now, and
        // only the latest context is ever delivered, which is exactly the
        // "what's true right now" semantics a Today snapshot wants.
        try? WCSession.default.updateApplicationContext(["snapshot": data])
    }
}

extension PhoneConnectivityBridge: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {}
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
}
