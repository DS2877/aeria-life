import SwiftUI

@main
struct AeriaApp: App {
    @StateObject private var environment = AppEnvironment()
    @AppStorage("aeria.hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // TEMPORARY diagnostic logging — see docs/ARCHITECTURE.md if this
        // is still here; safe to leave in; remove once launch is reliable.
        print("AeriaApp.init(): starting")
        // Must happen before the app finishes launching — Apple's own
        // guidance for BGTaskScheduler. App struct `init()` runs early
        // enough for a pure SwiftUI-lifecycle app with no AppDelegate.
        BackgroundRefreshScheduler.register()
        print("AeriaApp.init(): done")
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
            .task {
                PendingCaptureImporter.importPending(into: environment.mainContext)
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .background:
                BackgroundRefreshScheduler.scheduleNext()
            case .active:
                // Catches anything shared in while Aeria was backgrounded —
                // launch alone only catches it on a cold start.
                PendingCaptureImporter.importPending(into: environment.mainContext)
            default:
                break
            }
        }
    }
}
