import Foundation

/// A coarse classification of what the user is trying to do — master prompt
/// § 9: "classify intent, then ask only the minimum necessary clarification."
enum AeriaIntentKind: String, Codable, CaseIterable {
    case checkSchedule
    case findFreeTime
    case addTask
    case addReminder
    case addMemory
    case checkLife
    case searchLife
    case subscriptionQuestion
    case general
}

struct AeriaIntent {
    let kind: AeriaIntentKind
    /// Best-effort extracted title/subject, if the phrasing implies one
    /// ("remember that I..." → the remainder; "add ... to my list" → the
    /// task text).
    let extractedTitle: String?
    let extractedDate: Date?
    let confidence: ConfidenceLevel
}

/// The minimum slice of context a question needs to be answered — assembled
/// by the caller, not fetched by the provider. Keeping this explicit is a
/// privacy boundary (master prompt § 34, § 56): whatever intelligence layer
/// answers the question only ever sees what's listed here, never a live
/// handle to the whole store.
struct AeriaContextBundle {
    var now: Date = .now
    var currentMode: LifeMode = .home
    var todaysEvents: [CalendarEvent] = []
    var openTaskTitles: [String] = []
    var relevantMemories: [String] = []
    var freeIntervals: [DateInterval] = []
    var subscriptionMonthlyTotal: Decimal?
    var subscriptionCurrencyCode: String = Locale.current.currency?.identifier ?? "USD"
}

enum AeriaActionKind: String, Codable {
    case createReminder, createEvent, createTask, none
}

struct AeriaSuggestedAction {
    let title: String
    let kind: AeriaActionKind
    let proposedDate: Date?
}

/// A structured answer, not a chat bubble — master prompt § 66: Ask Aeria
/// renders this as headline + optional detail + an optional previewable
/// action, never a transcript.
struct AeriaResponse {
    let headline: String
    let detail: String?
    let suggestedAction: AeriaSuggestedAction?
    let confidence: ConfidenceLevel
}

/// The swappable intelligence backend. `RuleBasedIntelligenceProvider` is
/// the default (deterministic, always available, zero setup). A
/// FoundationModels-backed provider can be swapped in later — see
/// FoundationModelsIntelligenceProvider.swift — without anything above this
/// protocol changing.
protocol AeriaIntelligenceProviding {
    func classifyIntent(_ text: String) async -> AeriaIntent
    func respond(to question: String, context: AeriaContextBundle) async -> AeriaResponse
}
