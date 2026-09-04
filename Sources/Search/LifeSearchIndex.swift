import Foundation
import NaturalLanguage

struct SearchResult: Identifiable {
    let id: String
    let title: String
    let subtitle: String?
    let entityType: LifeEntityType
    let relevance: Double
}

/// Anything Life Search can return a result for. Each feature's view model
/// adapts its own models to this rather than the search index knowing about
/// SwiftData/EventKit types directly.
protocol SearchableRecord {
    var searchID: String { get }
    var searchTitle: String { get }
    var searchSubtitle: String? { get }
    var searchBody: String { get }
    var searchEntityType: LifeEntityType { get }
}

/// Master prompt § 22: "semantic, not merely keyword-based." Fully on-device
/// via `NaturalLanguage`'s sentence embeddings (no network, no backend) —
/// blended with plain substring matching so an exact title match always
/// still wins. This is a real, if modest, semantic layer: it will surface
/// "Audi" for a query like "car" even without the word appearing, because
/// their embeddings sit close together.
enum LifeSearchIndex {
    private static let embedding = NLEmbedding.sentenceEmbedding(for: .english)

    static func search<T: SearchableRecord>(_ query: String, in records: [T], limit: Int = 20) -> [SearchResult] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        let loweredQuery = trimmed.lowercased()
        let queryVector = embedding?.vector(for: trimmed)

        let scored: [(T, Double)] = records.map { record in
            var score = 0.0
            let title = record.searchTitle.lowercased()
            let body = record.searchBody.lowercased()

            if title == loweredQuery {
                score += 1.0
            } else if title.hasPrefix(loweredQuery) {
                score += 0.7
            } else if title.contains(loweredQuery) {
                score += 0.5
            }
            if body.contains(loweredQuery) {
                score += 0.2
            }

            if let queryVector,
               let recordVector = embedding?.vector(for: "\(record.searchTitle) \(record.searchBody)") {
                score += cosineSimilarity(queryVector, recordVector) * 0.4
            }
            return (record, score)
        }

        return scored
            .filter { $0.1 > 0.15 }
            .sorted { $0.1 > $1.1 }
            .prefix(limit)
            .map { record, score in
                SearchResult(
                    id: record.searchID,
                    title: record.searchTitle,
                    subtitle: record.searchSubtitle,
                    entityType: record.searchEntityType,
                    relevance: score
                )
            }
    }

    private static func cosineSimilarity(_ a: [Double], _ b: [Double]) -> Double {
        guard a.count == b.count, !a.isEmpty else { return 0 }
        var dot = 0.0, normA = 0.0, normB = 0.0
        for index in a.indices {
            dot += a[index] * b[index]
            normA += a[index] * a[index]
            normB += b[index] * b[index]
        }
        guard normA > 0, normB > 0 else { return 0 }
        return dot / (normA.squareRoot() * normB.squareRoot())
    }
}
