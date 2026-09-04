import AppIntents

/// Registers Aeria's intents as out-of-the-box Shortcuts/Siri phrases —
/// master prompt § 43: "use Apple's platform capabilities," not a bespoke
/// voice UI. `${applicationName}` resolves to the app's display name
/// ("Aeria") automatically.
///
/// Free-text `@Parameter`s (question/taskTitle/content are all plain
/// `String`) can't be embedded inside a phrase pattern — Apple only allows
/// that for `AppEntity`/`AppEnum`-typed parameters, i.e. a fixed set of
/// choices, not arbitrary typed text. Siri still prompts for the value
/// conversationally; the phrase just can't show it inline.
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
                "Ask \(.applicationName) a question",
            ],
            shortTitle: "Ask Aeria",
            systemImageName: "sparkle"
        )
        AppShortcut(
            intent: CreateTaskIntent(),
            phrases: [
                "Add a task to \(.applicationName)",
            ],
            shortTitle: "Add Task",
            systemImageName: "checkmark.circle.fill"
        )
        AppShortcut(
            intent: AddMemoryIntent(),
            phrases: [
                "Tell \(.applicationName) to remember something",
            ],
            shortTitle: "Remember",
            systemImageName: "brain"
        )
    }
}
