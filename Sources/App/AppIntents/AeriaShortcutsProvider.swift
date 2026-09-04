import AppIntents

/// Registers Aeria's intents as out-of-the-box Shortcuts/Siri phrases —
/// master prompt § 43: "use Apple's platform capabilities," not a bespoke
/// voice UI. `${applicationName}` resolves to the app's display name
/// ("Aeria") automatically.
struct AeriaShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CheckMyLifeIntent(),
            phrases: [
                "Check my life with \(.applicationName)",
                "What am I forgetting in \(.applicationName)",
            ],
            shortTitle: "Check My Life",
            systemImageName: "checkmark.circle"
        )
        AppShortcut(
            intent: AskAeriaIntent(),
            phrases: [
                "Ask \(.applicationName) \(\.$question)",
            ],
            shortTitle: "Ask Aeria",
            systemImageName: "sparkle"
        )
        AppShortcut(
            intent: CreateTaskIntent(),
            phrases: [
                "Add \(\.$taskTitle) to \(.applicationName)",
            ],
            shortTitle: "Add Task",
            systemImageName: "checkmark.circle.fill"
        )
        AppShortcut(
            intent: AddMemoryIntent(),
            phrases: [
                "Tell \(.applicationName) to remember \(\.$content)",
            ],
            shortTitle: "Remember",
            systemImageName: "brain"
        )
    }
}
