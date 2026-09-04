import Foundation

// MARK: - Opt-in upgrade path — not wired up by default

// `AppEnvironment` binds `AeriaIntelligenceProviding` to
// `RuleBasedIntelligenceProvider` (see App/AppEnvironment.swift), which is
// deterministic, ships with zero setup, and covers every example
// interaction in the master prompt § 8. This file is the on-device,
// privacy-first upgrade for genuinely open-ended phrasing that the rule
// engine can't classify — Apple's FoundationModels framework, which runs
// entirely on-device via Apple Intelligence (iOS 26+, no network call, no
// backend to build or pay for — the right fit for master prompt § 34's
// privacy stance).
//
// This framework was very new at the time this file was written, and its
// exact API was not something that could be verified without a Mac and
// Xcode 26 in the loop. If this file fails to build:
//   1. It is NOT required — RuleBasedIntelligenceProvider is the default
//      and the whole app works without this file.
//   2. Either delete this file, or paste the compiler error to Claude along
//      with a link to Apple's current FoundationModels documentation.
//
// To actually turn this on once it builds: change the binding in
// `AppEnvironment.swift` from `RuleBasedIntelligenceProvider()` to
// `HybridIntelligenceProvider()` below.

#if canImport(FoundationModels)
import FoundationModels

@available(iOS 26.0, *)
struct FoundationModelsIntelligenceProvider: AeriaIntelligenceProviding {
    private let fallback = RuleBasedIntelligenceProvider()

    /// The rule-based classifier already covers § 8's example phrasings
    /// deterministically and instantly, so intent classification stays on
    /// the fast, free path. The model is reserved for open-ended `respond`
    /// calls where a canned answer isn't possible.
    func classifyIntent(_ text: String) async -> AeriaIntent {
        await fallback.classifyIntent(text)
    }

    func respond(to question: String, context: AeriaContextBundle) async -> AeriaResponse {
        guard SystemLanguageModel.default.availability == .available else {
            return await fallback.respond(to: question, context: context)
        }
        do {
            let session = LanguageModelSession(instructions: Self.instructions)
            let prompt = Self.prompt(for: question, context: context)
            let result = try await session.respond(to: prompt)
            return AeriaResponse(
                headline: result.content,
                detail: nil,
                suggestedAction: nil,
                confidence: .high
            )
        } catch {
            return await fallback.respond(to: question, context: context)
        }
    }

    private static let instructions = """
    You are Aeria, a calm personal life assistant. Answer in one or two short \
    sentences, plainly, with no filler or enthusiasm. Only use the facts given \
    to you below — never invent a date, amount, or commitment that isn't there. \
    If you don't have enough information, say so plainly instead of guessing.
    """

    private static func prompt(for question: String, context: AeriaContextBundle) -> String {
        var lines = ["Question: \(question)", "Current time: \(context.now.formatted())"]
        if !context.todaysEvents.isEmpty {
            lines.append("Today's events: " + context.todaysEvents.map(\.title).joined(separator: ", "))
        }
        if !context.openTaskTitles.isEmpty {
            lines.append("Open tasks: " + context.openTaskTitles.joined(separator: ", "))
        }
        if !context.relevantMemories.isEmpty {
            lines.append("Known preferences: " + context.relevantMemories.joined(separator: "; "))
        }
        return lines.joined(separator: "\n")
    }
}

/// Routes intent classification (deterministic) through the rule engine and
/// open-ended answers through FoundationModels when available, falling back
/// silently otherwise. This is the type to bind in `AppEnvironment` once
/// `FoundationModelsIntelligenceProvider` above is verified to build.
@available(iOS 26.0, *)
typealias HybridIntelligenceProvider = FoundationModelsIntelligenceProvider
#endif
