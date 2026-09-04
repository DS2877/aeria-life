import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Life Mode") {
                    Picker("Override", selection: Binding(
                        get: { environment.manualLifeModeOverride },
                        set: { environment.manualLifeModeOverride = $0 }
                    )) {
                        Text("Automatic").tag(LifeMode?.none)
                        ForEach(LifeMode.allCases, id: \.self) { mode in
                            Text(mode.displayName).tag(LifeMode?.some(mode))
                        }
                    }
                    Text("Aeria infers your mode from time and calendar. Override it here if it's ever wrong — master prompt § 14: never trapped.")
                        .font(AeriaFont.caption)
                        .foregroundStyle(Palette.textSecondary)
                }

                Section {
                    NavigationLink {
                        PrivacyCenterView()
                    } label: {
                        Label("Privacy Center", systemImage: "hand.raised")
                    }
                }

                Section {
                    Button("Enable Notifications") {
                        Task { _ = await environment.notificationScheduler.requestAuthorization() }
                    }
                }

                Section("About") {
                    LabeledContent("Version", value: Bundle.main.appVersionDisplay)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private extension Bundle {
    var appVersionDisplay: String {
        let version = infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}
