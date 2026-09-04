import SwiftUI

/// Master prompt § 37: the Watch app answers "what's next / what matters,"
/// not a shrunken iPhone UI. One screen, no tabs.
@main
struct AeriaWatchApp: App {
    @StateObject private var connectivity = WatchConnectivityReceiver()

    var body: some Scene {
        WindowGroup {
            WatchTodayView()
                .environmentObject(connectivity)
        }
    }
}
