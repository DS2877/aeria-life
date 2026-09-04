import SwiftData
import SwiftUI

/// Master prompt § 22 Life Search: one search box across everything Aeria
/// knows, ranked semantically rather than by exact keyword match (see
/// LifeSearchIndex).
struct LifeSearchView: View {
    @State private var query = ""

    @Query private var people: [Person]
    @Query private var organizations: [Organization]
    @Query private var places: [Place]
    @Query private var tasks: [TaskItem]
    @Query private var commitments: [Commitment]
    @Query private var documents: [DocumentRecord]
    @Query private var assets: [Asset]
    @Query private var subscriptions: [Subscription]
    @Query private var goals: [Goal]
    @Query private var moments: [Moment]

    private var results: [SearchResult] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }
        var all: [SearchResult] = []
        all += LifeSearchIndex.search(query, in: people)
        all += LifeSearchIndex.search(query, in: organizations)
        all += LifeSearchIndex.search(query, in: places)
        all += LifeSearchIndex.search(query, in: tasks)
        all += LifeSearchIndex.search(query, in: commitments)
        all += LifeSearchIndex.search(query, in: documents)
        all += LifeSearchIndex.search(query, in: assets)
        all += LifeSearchIndex.search(query, in: subscriptions)
        all += LifeSearchIndex.search(query, in: goals)
        all += LifeSearchIndex.search(query, in: moments)
        return all.sorted { $0.relevance > $1.relevance }
    }

    var body: some View {
        VStack {
            if query.isEmpty {
                EmptyStateView(
                    symbolName: "magnifyingglass",
                    title: "Search your life",
                    message: "People, places, documents, subscriptions, tasks — everything Aeria knows, in one place."
                )
                .padding(.top, Metrics.spacingXXL)
                Spacer()
            } else if results.isEmpty {
                EmptyStateView(symbolName: "questionmark.circle", title: "No matches", message: nil)
                    .padding(.top, Metrics.spacingXXL)
                Spacer()
            } else {
                List(results) { result in
                    HStack(spacing: Metrics.spacingM) {
                        Image(systemName: symbolName(for: result.entityType))
                            .foregroundStyle(Palette.textSecondary)
                            .frame(width: 22)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(result.title).foregroundStyle(Palette.textPrimary)
                            if let subtitle = result.subtitle {
                                Text(subtitle)
                                    .font(AeriaFont.caption)
                                    .foregroundStyle(Palette.textSecondary)
                            }
                        }
                    }
                    .listRowBackground(Palette.canvas)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .searchable(text: $query, prompt: "Search your life")
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func symbolName(for type: LifeEntityType) -> String {
        switch type {
        case .person: return "person.fill"
        case .organization: return "building.2.fill"
        case .place: return "mappin.circle.fill"
        case .task: return "checkmark.circle"
        case .commitment: return "text.bubble"
        case .document: return "doc.text"
        case .asset: return "cube.fill"
        case .subscription: return "arrow.triangle.2.circlepath"
        case .goal: return "target"
        case .moment: return "sparkles"
        default: return "circle"
        }
    }
}
