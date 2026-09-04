import Foundation

/// A light nudge, not an auto-filer — master prompt § 9 "classify intent,"
/// applied to Life Inbox captures. Detects phrasing that sounds like a
/// promise ("I'll...", "I promise to...") so the Inbox can visually
/// highlight the right filing button, without ever filing it on the user's
/// behalf (master prompt § 6 "Rule 6: never make the user manage the
/// system unnecessarily" cuts both ways — Aeria also never decides for
/// them without a tap).
enum CommitmentExtractor {
    private static let phrases = [
        "i'll ", "i will ", "i promise to ", "i owe ", "i need to send",
        "i need to call", "i need to email", "i'm going to", "i am going to",
    ]

    static func looksLikeCommitment(_ text: String) -> Bool {
        let lowered = text.lowercased()
        return phrases.contains { lowered.contains($0) }
    }
}
