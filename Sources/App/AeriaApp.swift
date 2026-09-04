import SwiftUI

@main
struct AeriaApp: App {
    @StateObject private var environment = AppEnvironment()
    @AppStorage("aeria.hasCompletedOnboarding") private var hasCompletedOnboarding = false

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
    }
}
