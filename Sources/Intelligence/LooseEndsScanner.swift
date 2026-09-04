import Foundation

/// One open loop — master prompt § 11 "What am I forgetting?" / § 73 "Loose
/// Ends". Copy is generated with the calm hedging language the master
/// prompt specifies verbatim ("You mentioned…", "approaching…") — never an
/// alarming tone.
struct LooseEnd: Identifiable {
    let id: String
    let summary: String
    let detail: String?
    let relatedEntityType: LifeEntityType
    let relatedEntityID: String
}

/// Pure scan over already-fetched records — master prompt § 11: unfinished
/// plans, approaching renewals, unpaid tasks tied to upcoming events, and
/// stale captures. Each rule below cites the section of § 11 it implements.
enum LooseEndsScanner {
    static func scan(
        now: Date = .now,
        calendar: Calendar = .current,
        commitments: [Commitment],
        documents: [DocumentRecord],
        upcomingPayments: [PaymentItem],
        unprocessedNotes: [NoteItem]
    ) -> [LooseEnd] {
        var results: [LooseEnd] = []

        // "You mentioned booking an appointment 12 days ago."
        for commitment in commitments where !commitment.isFulfilled && !commitment.isArchived {
            let days = calendar.dateComponents([.day], from: commitment.createdAt, to: now).day ?? 0
            guard days >= 3 else { continue }
            results.append(LooseEnd(
                id: "commitment-\(commitment.id.uuidString)",
                summary: "You mentioned: \(commitment.text)",
                detail: "\(days) day\(days == 1 ? "" : "s") ago",
                relatedEntityType: .commitment,
                relatedEntityID: commitment.id.uuidString
            ))
        }

        // "Your insurance renewal is approaching."
        for document in documents where !document.isArchived {
            guard let expiry = document.expiryDate else { continue }
            let days = calendar.dateComponents([.day], from: now, to: expiry).day ?? Int.max
            guard days >= 0, days <= 30 else { continue }
            results.append(LooseEnd(
                id: "document-\(document.id.uuidString)",
                summary: "\(document.title) is approaching",
                detail: days == 0 ? "Today" : "In \(days) day\(days == 1 ? "" : "s")",
                relatedEntityType: .document,
                relatedEntityID: document.id.uuidString
            ))
        }

        // "You have an unpaid task associated with an upcoming event." —
        // approximated here as an unpaid payment due soon.
        for payment in upcomingPayments where !payment.isPaid && !payment.isArchived {
            guard let due = payment.dueDate else { continue }
            let days = calendar.dateComponents([.day], from: now, to: due).day ?? Int.max
            guard days >= 0, days <= 7 else { continue }
            results.append(LooseEnd(
                id: "payment-\(payment.id.uuidString)",
                summary: "\(payment.title) is due",
                detail: days == 0 ? "Today" : "In \(days) day\(days == 1 ? "" : "s")",
                relatedEntityType: .payment,
                relatedEntityID: payment.id.uuidString
            ))
        }

        // "You started planning ... but haven't finished." — a Life Inbox
        // capture that's sat unsorted for a while.
        for note in unprocessedNotes where !note.isProcessed {
            let days = calendar.dateComponents([.day], from: note.createdAt, to: now).day ?? 0
            guard days >= 5 else { continue }
            results.append(LooseEnd(
                id: "note-\(note.id.uuidString)",
                summary: "This looks unfinished — captured \(days) days ago",
                detail: note.rawText,
                relatedEntityType: .note,
                relatedEntityID: note.id.uuidString
            ))
        }

        return results
    }
}
