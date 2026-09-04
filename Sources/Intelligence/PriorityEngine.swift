import Foundation

/// One candidate item the Priority Engine can rank — a normalized view over
/// whatever mix of TaskItem/Commitment/CalendarEvent/PaymentItem/etc. Today
/// wants to consider. Building this adapter per-source keeps the engine
/// itself free of any knowledge of SwiftData or EventKit (master prompt § 7:
/// score, don't couple to storage).
struct PriorityInput: Identifiable {
    let id: String
    let title: String
    let dueDate: Date?
    /// 0...1 default weight for this kind of thing before context is
    /// applied — e.g. an overdue Commitment starts higher than a Habit
    /// nudge.
    let baseImportance: Double
    let isUserPinned: Bool
    let isRelevantToCurrentLocation: Bool
    let confidence: ConfidenceLevel
    let entityType: LifeEntityType
}

/// Master prompt § 7: score everything, surface only what clears the bar.
/// Pure and deterministic on purpose — no hidden state, no async, so it's
/// trivially unit-testable (see AeriaTests/PriorityEngineTests) and cheap
/// enough to re-run on every context change.
enum PriorityEngine {
    /// Anything scoring below this is suppressed from Today entirely —
    /// "nothing important needs your attention" is a valid, intended result
    /// (master prompt § 7).
    static let surfaceThreshold: Double = 0.35

    static func score(_ input: PriorityInput, now: Date = .now) -> Double {
        var score = input.baseImportance

        if let dueDate = input.dueDate {
            let hoursUntilDue = dueDate.timeIntervalSince(now) / 3600
            switch hoursUntilDue {
            case ..<0: score += 0.5 // overdue
            case 0..<24: score += 0.4
            case 24..<72: score += 0.22
            case 72..<168: score += 0.1
            default: break
            }
        }

        if input.isUserPinned {
            score += 0.3
        }
        if input.isRelevantToCurrentLocation {
            score += 0.12
        }
        if input.confidence == .low {
            // Worth surfacing, but nudged down until the user confirms it —
            // an unconfirmed guess shouldn't outrank a confirmed fact.
            score *= 0.75
        }

        return min(score, 1.0)
    }

    /// Ranks and filters candidates to what's actually worth showing.
    /// `limit` caps the count even when more clear the threshold — Today
    /// should never turn into a list (master prompt § 6–7).
    static func rank(_ inputs: [PriorityInput], now: Date = .now, limit: Int? = nil) -> [PriorityInput] {
        let scored = inputs
            .map { ($0, score($0, now: now)) }
            .filter { $0.1 >= surfaceThreshold }
            .sorted { $0.1 > $1.1 }
            .map { $0.0 }
        guard let limit else { return scored }
        return Array(scored.prefix(limit))
    }

    /// Master prompt § 68 "One Thing": when several items clear the
    /// threshold but one clearly dominates, Aeria can reduce to a single
    /// recommendation. Returns nil unless the top item is decisively ahead.
    static func oneThing(_ inputs: [PriorityInput], now: Date = .now) -> PriorityInput? {
        let ranked = inputs.map { ($0, score($0, now: now)) }.sorted { $0.1 > $1.1 }
        guard let top = ranked.first, top.1 >= 0.75 else { return nil }
        if let second = ranked.dropFirst().first, top.1 - second.1 < 0.2 {
            return nil // too close to call — don't pretend there's one thing
        }
        return top.0
    }
}
