import SwiftUI

@main
struct AeriaApp: App {
    @StateObject private var environment = AppEnvironment()
    @AppStorage("aeria.hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // Must happen before the app finishes launching — Apple's own
        // guidance for BGTaskScheduler. App struct `init()` runs early
        // enough for a pure SwiftUI-lifecycle app with no AppDelegate.
        BackgroundRefreshScheduler.register()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    RootTabView()
                } else {
                    OnboardingView {
                        hasCompletedOnboarding = true
                    }
                }
            }
            .appThemeBackground()
            .environmentObject(environment)
            .modelContainer(environment.modelContainer)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                BackgroundRefreshScheduler.scheduleNext()
            }
        }
    }
}
