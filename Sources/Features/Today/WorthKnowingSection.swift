import SwiftUI

/// Master prompt § 6, § 7: a short, aggressively-filtered list of things
/// worth knowing right now — a weather change, an approaching renewal.
/// Never a full feed; `items` should already be capped by the caller.
struct WorthKnowingSection: View {
    struct Item: Identifiable {
        let id: String
        let symbolName: String
        let title: String
        let detail: String?
        var confidence: ConfidenceLevel = .confirmed
        var tint: Color = Palette.textSecondary
        var onHandle: (() -> Void)?
    }

    let items: [Item]

    var body: some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: Metrics.spacingM) {
                SectionHeader(title: "Worth knowing")
                SurfaceCard {
                    VStack(alignment: .leading, spacing: Metrics.spacingM) {
                        ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                            if index > 0 {
                                Divider().overlay(Palette.hairline)
                            }
                            InsightRow(
                                symbolName: item.symbolName,
                                title: item.title,
                                detail: item.detail,
                                confidence: item.confidence,
                                tint: item.tint,
                                onHandle: item.onHandle
                            )
                        }
                    }
                }
            }
        }
    }
}
