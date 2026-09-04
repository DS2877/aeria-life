import Foundation
import SwiftData

enum BillingFrequency: String, Codable, CaseIterable {
    case weekly, monthly, quarterly, yearly

    /// Times per year this frequency bills, for annualizing cost.
    var occurrencesPerYear: Double {
        switch self {
        case .weekly: return 52
        case .monthly: return 12
        case .quarterly: return 4
        case .yearly: return 1
        }
    }
}

enum MoneyCategory: String, Codable, CaseIterable {
    case streaming, software, fitness, utility, housing, insurance, transport, other
}

/// A recurring expense — master prompt § 19 Subscription Radar. Awareness,
/// not budgeting: Aeria surfaces the annualized cost and flags subscriptions
/// that look dormant, and stops there.
@Model
final class Subscription {
    @Attribute(.unique) var id: UUID
    var name: String
    var amount: Decimal
    var currencyCode: String
    var frequency: BillingFrequency
    var nextChargeDate: Date?
    var category: MoneyCategory
    var organizationID: String?
    var isActive: Bool
    /// Last time Aeria saw evidence this is still being used (a calendar
    /// event, an app open, a manual confirmation). Nil means never assessed.
    /// Used to power "hasn't appeared relevant recently."
    var lastRelevantAt: Date?
    var notes: String
    var provenance: Provenance
    var createdAt: Date
    var updatedAt: Date
    var isArchived: Bool

    var annualizedCost: Decimal {
        amount * Decimal(frequency.occurrencesPerYear)
    }

    var monthlyEquivalentCost: Decimal {
        annualizedCost / 12
    }

    init(
        name: String,
        amount: Decimal,
        currencyCode: String = Locale.current.currency?.identifier ?? "USD",
        frequency: BillingFrequency,
        category: MoneyCategory,
        provenance: Provenance = .userProvided,
        createdAt: Date = .now
    ) {
        self.id = UUID()
        self.name = name
        self.amount = amount
        self.currencyCode = currencyCode
        self.frequency = frequency
        self.nextChargeDate = nil
        self.category = category
        self.organizationID = nil
        self.isActive = true
        self.lastRelevantAt = nil
        self.notes = ""
        self.provenance = provenance
        self.createdAt = createdAt
        self.updatedAt = createdAt
        self.isArchived = false
    }
}

/// A one-off or irregular upcoming payment — a bill, an invoice, a deposit.
/// Kept separate from `Subscription`, which is specifically recurring.
@Model
final class PaymentItem {
    @Attribute(.unique) var id: UUID
    var title: String
    var amount: Decimal
    var currencyCode: String
    var dueDate: Date?
    var isPaid: Bool
    var paidAt: Date?
    var category: MoneyCategory
    var organizationID: String?
    var notes: String
    var provenance: Provenance
    var createdAt: Date
    var updatedAt: Date
    var isArchived: Bool

    init(
        title: String,
        amount: Decimal,
        currencyCode: String = Locale.current.currency?.identifier ?? "USD",
        dueDate: Date? = nil,
        category: MoneyCategory,
        provenance: Provenance = .userProvided,
        createdAt: Date = .now
    ) {
        self.id = UUID()
        self.title = title
        self.amount = amount
        self.currencyCode = currencyCode
        self.dueDate = dueDate
        self.isPaid = false
        self.paidAt = nil
        self.category = category
        self.organizationID = nil
        self.notes = ""
        self.provenance = provenance
        self.createdAt = createdAt
        self.updatedAt = createdAt
        self.isArchived = false
    }
}
