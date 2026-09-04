import SwiftUI

/// Master prompt § 36: TODAY / LIFE / ✦ AERIA / VAULT — four tabs, no fifth
/// unless genuinely necessary. Search, Settings, and Privacy Center are all
/// reached from within these (toolbar buttons / sheets), not additional
/// tabs.
struct RootTabView: View {
    @State private var selectedTab: Tab = .today
    @State private var isShowingSettings = false

    enum Tab {
        case today, life, ask, vault
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                TodayView(isShowingSettings: $isShowingSettings)
            }
            .tabItem { Label("Today", systemImage: "sun.max.fill") }
            .tag(Tab.today)

            NavigationStack {
                LifeView()
            }
            .tabItem { Label("Life", systemImage: "circle.grid.3x3.fill") }
            .tag(Tab.life)

            NavigationStack {
                AskAeriaView()
            }
            .tabItem { Label("Aeria", systemImage: "sparkle") }
            .tag(Tab.ask)

            NavigationStack {
                VaultView()
            }
            .tabItem { Label("Vault", systemImage: "lock.shield.fill") }
            .tag(Tab.vault)
        }
        .sheet(isPresented: $isShowingSettings) {
            SettingsView()
        }
    }
}
