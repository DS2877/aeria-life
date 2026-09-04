import SwiftData
import SwiftUI

/// "Check my life" — master prompt § 11, the flagship "What am I
/// forgetting?" feature. Full-screen version of the Loose Ends summary
/// shown on `LifeView`.
struct LooseEndsView: View {
    @Query(filter: #Predicate<Commitment> { !$0.isArchived }) private var commitments: [Commitment]
    @Query(filter: #Predicate<DocumentRecord> { !$0.isArchived }) private var documents: [DocumentRecord]
    @Query(filter: #Predicate<PaymentItem> { !$0.isArchived }) private var payments: [PaymentItem]
    @Query private var notes: [NoteItem]

    private var looseEnds: [LooseEnd] {
        LooseEndsScanner.scan(
            commitments: commitments,
            documents: documents,
            upcomingPayments: payments,
            unprocessedNotes: notes
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Metrics.spacingL) {
                if looseEnds.isEmpty {
                    EmptyStateView(
                        symbolName: "checkmark.circle",
                        title: "Nothing looks unfinished",
                        message: "Aeria checked your commitments, documents, and captures — nothing needs attention right now."
                    )
                    .padding(.top, Metrics.spacingXXL)
                } else {
                    SurfaceCard {
                        VStack(alignment: .leading, spacing: Metrics.spacingM) {
                            ForEach(Array(looseEnds.enumerated()), id: \.element.id) { index, end in
                                if index > 0 { Divider().overlay(Palette.hairline) }
                                InsightRow(
                                    symbolName: symbolName(for: end.relatedEntityType),
                                    title: end.summary,
                                    detail: end.detail,
                                    tint: Palette.notice
                                )
                            }
                        }
                    }
                }
            }
            .padding(Metrics.screenPadding)
        }
        .navigationTitle("Check My Life")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func symbolName(for type: LifeEntityType) -> String {
        switch type {
        case .document: return "doc.text"
        case .payment: return "creditcard"
        case .commitment: return "text.bubble"
        case .note: return "tray"
        default: return "sparkle"
        }
    }
}
