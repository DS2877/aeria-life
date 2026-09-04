import Foundation

/// Where a fact came from. Every fact Aeria holds must be traceable to one of
/// these — see master prompt § 5 Information Model, § 56 AI Source
/// Transparency. Never collapse this into a single "source: String"; the UI
/// (confidence badges, "What Aeria Knows") branches on the case, not the text.
enum Provenance: String, Codable, CaseIterable, Hashable {
    /// The user typed, said, or confirmed this directly.
    case userProvided
    /// Read from an Apple system source the user granted access to
    /// (EventKit, Contacts, Photos location, etc.) — treated as ground truth.
    case systemData
    /// Brought in from an external import (a receipt PDF, a CSV, a shared file).
    case imported
    /// Aeria derived this from other facts (e.g. "you're usually free Tuesday
    /// evenings" from calendar history). Present as inference, not fact.
    case aiInference
    /// Aeria is proposing this; nothing has been created or changed yet.
    case aiSuggestion

    /// Whether this fact can be shown as settled truth without a hedge word.
    var isAuthoritative: Bool {
        switch self {
        case .userProvided, .systemData: return true
        case .imported, .aiInference, .aiSuggestion: return false
        }
    }
}

/// How sure Aeria is about an inferred or extracted fact. Confidence is
/// orthogonal to provenance: a `.systemData` fact is always `.confirmed`,
/// while an `.imported` or `.aiInference` fact carries a real confidence
/// score computed by whatever produced it (see DocumentExtractor,
/// AeriaIntelligenceProvider).
enum ConfidenceLevel: Comparable, Codable {
    /// User-provided or system data — not a guess, don't hedge in copy.
    case confirmed
    /// High-confidence extraction/inference — state it plainly but keep the
    /// fact editable and attributable (master prompt § 55).
    case high
    /// Worth surfacing but must be phrased with a hedge ("appears to…") and
    /// ideally asks for confirmation before anything downstream relies on it.
    case low

    init(score: Double) {
        switch score {
        case 0.85...: self = .high
        default: self = .low
        }
    }

    /// Copy hedge to prefix an AI-derived statement with. Empty for confirmed
    /// facts, which should read as plain statements.
    var hedgePrefix: String {
        switch self {
        case .confirmed, .high: return ""
        case .low: return "This appears to be "
        }
    }

    /// Swift doesn't synthesize `Comparable` for enums — this orders by
    /// trust, least to most: `.low < .high < .confirmed`, independent of
    /// declaration order above (which is grouped by doc-comment topic, not
    /// rank).
    private var trustRank: Int {
        switch self {
        case .low: return 0
        case .high: return 1
        case .confirmed: return 2
        }
    }

    static func < (lhs: ConfidenceLevel, rhs: ConfidenceLevel) -> Bool {
        lhs.trustRank < rhs.trustRank
    }
}

/// Attaches provenance + confidence to a single field or fact, so the UI can
/// render the right badge/hedge without re-deriving it. Store this alongside
/// any model field that isn't unambiguously user-entered.
struct FactAttribution: Codable {
    var provenance: Provenance
    var confidence: ConfidenceLevel
    /// Free-text pointer to the source for "Based on N sources" drill-in —
    /// e.g. a document id, a calendar event id, or a memory fact id.
    var sourceIDs: [String]
    var recordedAt: Date

    static func userProvided(at date: Date = .now) -> FactAttribution {
        FactAttribution(provenance: .userProvided, confidence: .confirmed, sourceIDs: [], recordedAt: date)
    }

    static func systemData(sourceID: String, at date: Date = .now) -> FactAttribution {
        FactAttribution(provenance: .systemData, confidence: .confirmed, sourceIDs: [sourceID], recordedAt: date)
    }

    static func inferred(confidence: ConfidenceLevel, sourceIDs: [String], at date: Date = .now) -> FactAttribution {
        FactAttribution(provenance: .aiInference, confidence: confidence, sourceIDs: sourceIDs, recordedAt: date)
    }
}
