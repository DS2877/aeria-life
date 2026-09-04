import Foundation
import WatchConnectivity

/// Receives whatever `TodaySnapshot` the phone last pushed via
/// `PhoneConnectivityBridge`. This is the watch app's *only* source of
/// data — it never talks to EventKit or SwiftData itself.
@MainActor
final class WatchConnectivityReceiver: NSObject, ObservableObject {
    @Published private(set) var snapshot: TodaySnapshot = .empty

    override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    private func apply(_ context: [String: Any]) {
        guard let data = context["snapshot"] as? Data,
              let decoded = try? JSONDecoder().decode(TodaySnapshot.self, from: data) else { return }
        Task { @MainActor in self.snapshot = decoded }
    }
}

extension WatchConnectivityReceiver: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {
        Task { @MainActor in self.apply(session.receivedApplicationContext) }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        Task { @MainActor in self.apply(applicationContext) }
    }
}
