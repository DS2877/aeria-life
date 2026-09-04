import Foundation

/// The default `AeriaIntelligenceProviding` implementation: deterministic,
/// on-device, zero setup, zero network. Deliberately not "AI" in the
/// generative sense — it's keyword + date-detector based — but it covers
/// every example interaction in the master prompt § 8 without needing a
/// model, and it's what every device can run on day one. Swap in
/// `FoundationModelsIntelligenceProvider` later for genuinely open-ended
/// questions; keep this one as the always-available fallback either way.
struct RuleBasedIntelligenceProvider: AeriaIntelligenceProviding {
    private static let dateDetector = try? NSDataDetector(
        types: NSTextCheckingResult.CheckingType.date.rawValue
    )

    func classifyIntent(_ text: String) async -> AeriaIntent {
        let lowered = text.lowercased()
        let date = Self.firstDetectedDate(in: text)

        func intent(_ kind: AeriaIntentKind, title: String? = nil, confidence: ConfidenceLevel = .high) -> AeriaIntent {
            AeriaIntent(kind: kind, extractedTitle: title, extractedDate: date, confidence: confidence)
        }

        if lowered.contains("what am i forgetting") || lowered.contains("check my life")
            || lowered.contains("loose end") {
            return intent(.checkLife)
        }
        if lowered.contains("free evening") || lowered.contains("free time")
            || lowered.contains("fit in") || lowered.contains("find me a free")
            || lowered.contains("when can i") {
            return intent(.findFreeTime)
        }
        if lowered.contains("subscription") || lowered.contains("recurring") {
            return intent(.subscriptionQuestion)
        }
        if let title = extractedTitle(after: "remember that", in: text)
            ?? extractedTitle(after: "remember i", in: text)
            ?? extractedTitle(after: "remember my", in: text) {
            return intent(.addMemory, title: title)
        }
        if let title = extractedTitle(after: "remind me to", in: text)
            ?? extractedTitle(after: "remind me", in: text) {
            return intent(.addReminder, title: title)
        }
        if let title = extractedTitle(after: "add", in: text, upToOptional: "to my list")
            ?? extractedTitle(after: "i need to", in: text) {
            return intent(.addTask, title: title)
        }
        if lowered.contains("what's next") || lowered.contains("whats next")
            || lowered.contains("what do i have") || lowered.contains("my schedule")
            || lowered.contains("leave") {
            return intent(.checkSchedule)
        }
        if lowered.split(separator: " ").count <= 2, date == nil {
            return intent(.searchLife, title: text, confidence: .low)
        }
        return intent(.general, title: text, confidence: .low)
    }

    func respond(to question: String, context: AeriaContextBundle) async -> AeriaResponse {
        let intent = await classifyIntent(question)
        switch intent.kind {
        case .checkSchedule:
            return scheduleResponse(context: context)
        case .findFreeTime:
            return freeTimeResponse(context: context)
        case .subscriptionQuestion:
            return subscriptionResponse(context: context)
        case .checkLife:
            return AeriaResponse(
                headline: "Open Check My Life to see what's unfinished.",
                detail: nil,
                suggestedAction: nil,
                confidence: .confirmed
            )
        case .addReminder, .addTask, .addMemory:
            return AeriaResponse(
                headline: intent.extractedTitle.map { "Ready to save: \($0)" } ?? "What should Aeria remember?",
                detail: nil,
                suggestedAction: intent.extractedTitle.map {
                    AeriaSuggestedAction(
                        title: $0,
                        kind: intent.kind == .addReminder ? .createReminder : .createTask,
                        proposedDate: intent.extractedDate
                    )
                },
                confidence: .high
            )
        case .searchLife, .general:
            return AeriaResponse(
                headline: "I don't have enough information to answer that confidently.",
                detail: "Try Life Search, or ask about your schedule, free time, or subscriptions.",
                suggestedAction: nil,
                confidence: .low
            )
        }
    }

    // MARK: - Response builders

    private func scheduleResponse(context: AeriaContextBundle) -> AeriaResponse {
        guard let next = context.todaysEvents.first(where: { $0.startDate > context.now }) else {
            return AeriaResponse(
                headline: "Nothing else on your calendar today.",
                detail: nil,
                suggestedAction: nil,
                confidence: .confirmed
            )
        }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let remaining = context.todaysEvents.filter { $0.startDate > context.now }.count - 1
        let detail = remaining > 0 ? "\(remaining) more after that." : nil
        return AeriaResponse(
            headline: "Next: \(next.title) at \(formatter.string(from: next.startDate)).",
            detail: detail,
            suggestedAction: nil,
            confidence: .confirmed
        )
    }

    private func freeTimeResponse(context: AeriaContextBundle) -> AeriaResponse {
        guard let interval = context.freeIntervals.first(where: { $0.duration >= 45 * 60 }) else {
            return AeriaResponse(
                headline: "I don't see a solid gap in the time I can see.",
                detail: "Try widening the window, or check your calendar directly.",
                suggestedAction: nil,
                confidence: .low
            )
        }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let minutes = Int(interval.duration / 60)
        return AeriaResponse(
            headline: "You have \(minutes) minutes free from \(formatter.string(from: interval.start)).",
            detail: nil,
            suggestedAction: nil,
            confidence: .confirmed
        )
    }

    private func subscriptionResponse(context: AeriaContextBundle) -> AeriaResponse {
        guard let total = context.subscriptionMonthlyTotal else {
            return AeriaResponse(
                headline: "I don't have your subscriptions tracked yet.",
                detail: "Add one from Vault → Subscriptions.",
                suggestedAction: nil,
                confidence: .low
            )
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = context.subscriptionCurrencyCode
        let monthly = formatter.string(from: total as NSDecimalNumber) ?? "\(total)"
        let annual = formatter.string(from: (total * 12) as NSDecimalNumber) ?? "\(total * 12)"
        return AeriaResponse(
            headline: "Your recurring commitments are about \(monthly)/month.",
            detail: "That's \(annual)/year.",
            suggestedAction: nil,
            confidence: .confirmed
        )
    }

    // MARK: - Extraction helpers

    private static func firstDetectedDate(in text: String) -> Date? {
        guard let detector = dateDetector else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        return detector.matches(in: text, range: range).first?.date
    }

    private func extractedTitle(after prefix: String, in text: String, upToOptional suffix: String? = nil) -> String? {
        let lowered = text.lowercased()
        guard let prefixRange = lowered.range(of: prefix) else { return nil }
        var remainder = String(text[prefixRange.upperBound...]).trimmingCharacters(in: .whitespaces)
        if let suffix, let suffixRange = remainder.lowercased().range(of: suffix) {
            remainder = String(remainder[..<suffixRange.lowerBound]).trimmingCharacters(in: .whitespaces)
        }
        return remainder.isEmpty ? nil : remainder
    }
}
