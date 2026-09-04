import AppIntents
import EventKit
import SwiftData

/// Master prompt § 42–43: expose Aeria's core actions to Shortcuts/Siri.
/// Every intent here runs in-process (no separate Intents Extension target)
/// against `PersistenceController.shared` — the same store the app itself
/// reads and writes, so something created via Siri shows up in the app
/// immediately and vice versa.
///
/// Deliberately kept to plain "action → spoken confirmation" intents rather
/// than building custom `AppEntity`/`EntityQuery` result types for each —
/// that's real additional ceremony this pass didn't need to take on to make
/// Aeria's actions genuinely reachable from outside the app.

struct CreateTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Task to Aeria"
    static var description = IntentDescription("Adds a task to Aeria's Life Inbox.")

    @Parameter(title: "Task")
    var taskTitle: String

    @Parameter(title: "Due Date")
    var dueDate: Date?

    static var parameterSummary: some ParameterSummary {
        Summary("Add \(\.$taskTitle) to Aeria")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let context = PersistenceController.shared.mainContext
        context.insert(TaskItem(title: taskTitle, dueDate: dueDate, provenance: .userProvided))
        return .result(dialog: "Added \"\(taskTitle)\" to Aeria.")
    }
}

struct AddMemoryIntent: AppIntent {
    static var title: LocalizedStringResource = "Remember with Aeria"
    static var description = IntentDescription("Tells Aeria something to remember, the same as saying \"Remember that…\" in Ask Aeria.")

    @Parameter(title: "What should Aeria remember?")
    var content: String

    static var parameterSummary: some ParameterSummary {
        Summary("Remember \(\.$content)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let context = PersistenceController.shared.mainContext
        context.insert(MemoryFact(content: content, kind: .explicitPreference, provenance: .userProvided))
        return .result(dialog: "Got it — I'll remember that.")
    }
}

struct CheckMyLifeIntent: AppIntent {
    static var title: LocalizedStringResource = "Check My Life"
    static var description = IntentDescription("Asks Aeria what's worth knowing right now — master prompt § 11.")

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let context = PersistenceController.shared.mainContext
        let commitments = (try? context.fetch(FetchDescriptor<Commitment>())) ?? []
        let documents = (try? context.fetch(FetchDescriptor<DocumentRecord>())) ?? []
        let payments = (try? context.fetch(FetchDescriptor<PaymentItem>())) ?? []
        let notes = (try? context.fetch(FetchDescriptor<NoteItem>())) ?? []

        let looseEnds = LooseEndsScanner.scan(
            commitments: commitments.filter { !$0.isArchived },
            documents: documents.filter { !$0.isArchived },
            upcomingPayments: payments.filter { !$0.isArchived },
            unprocessedNotes: notes
        )

        if looseEnds.isEmpty {
            return .result(dialog: "Nothing looks unfinished right now.")
        }
        let headline = looseEnds.count == 1 ? "One thing worth a look: \(looseEnds[0].summary)."
            : "\(looseEnds.count) things worth a look. First: \(looseEnds[0].summary)."
        return .result(dialog: "\(headline)")
    }
}

struct AskAeriaIntent: AppIntent {
    static var title: LocalizedStringResource = "Ask Aeria"
    static var description = IntentDescription("Asks Aeria a question about your day, free time, or subscriptions.")

    @Parameter(title: "Question")
    var question: String

    static var parameterSummary: some ParameterSummary {
        Summary("Ask Aeria \(\.$question)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        var context = AeriaContextBundle()

        // Only populate calendar data if Aeria genuinely has access —
        // otherwise the rule-based provider's "nothing on your calendar"
        // phrasing would misrepresent "I didn't check" as "there's nothing
        // there" (master prompt § 57: say what you don't know).
        let store = EKEventStore()
        if EKEventStore.authorizationStatus(for: .event) == .fullAccess {
            let calendar = Calendar.current
            let now = Date()
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) ?? now
            let predicate = store.predicateForEvents(withStart: now, end: endOfDay, calendars: nil)
            context.todaysEvents = store.events(matching: predicate)
                .sorted { $0.startDate < $1.startDate }
                .map(CalendarEvent.init)
            context.freeIntervals = CalendarContextProvider().freeIntervals(from: now, to: endOfDay, minimumDuration: 30 * 60)
        }

        let modelContext = PersistenceController.shared.mainContext
        let subscriptions = ((try? modelContext.fetch(FetchDescriptor<Subscription>())) ?? []).filter(\.isActive)
        if !subscriptions.isEmpty {
            context.subscriptionMonthlyTotal = subscriptions.reduce(Decimal(0)) { $0 + $1.monthlyEquivalentCost }
            context.subscriptionCurrencyCode = subscriptions.first?.currencyCode ?? context.subscriptionCurrencyCode
        }

        let response = await RuleBasedIntelligenceProvider().respond(to: question, context: context)
        let spoken = [response.headline, response.detail].compactMap { $0 }.joined(separator: " ")
        return .result(dialog: "\(spoken)")
    }
}
