import Foundation

extension Person: SearchableRecord {
    var searchID: String { id.uuidString }
    var searchTitle: String { name }
    var searchSubtitle: String? { relationshipLabel.isEmpty ? nil : relationshipLabel }
    var searchBody: String { notes }
    var searchEntityType: LifeEntityType { .person }
}

extension Organization: SearchableRecord {
    var searchID: String { id.uuidString }
    var searchTitle: String { name }
    var searchSubtitle: String? { category.rawValue.capitalized }
    var searchBody: String { notes }
    var searchEntityType: LifeEntityType { .organization }
}

extension Place: SearchableRecord {
    var searchID: String { id.uuidString }
    var searchTitle: String { name }
    var searchSubtitle: String? { category.rawValue.capitalized }
    var searchBody: String { address }
    var searchEntityType: LifeEntityType { .place }
}

extension TaskItem: SearchableRecord {
    var searchID: String { id.uuidString }
    var searchTitle: String { title }
    var searchSubtitle: String? { dueDate?.formatted(date: .abbreviated, time: .omitted) }
    var searchBody: String { notes }
    var searchEntityType: LifeEntityType { .task }
}

extension Commitment: SearchableRecord {
    var searchID: String { id.uuidString }
    var searchTitle: String { text }
    var searchSubtitle: String? { dueHint.isEmpty ? nil : dueHint }
    var searchBody: String { "" }
    var searchEntityType: LifeEntityType { .commitment }
}

extension DocumentRecord: SearchableRecord {
    var searchID: String { id.uuidString }
    var searchTitle: String { title }
    var searchSubtitle: String? { category.displayName }
    var searchBody: String { notes }
    var searchEntityType: LifeEntityType { .document }
}

extension Asset: SearchableRecord {
    var searchID: String { id.uuidString }
    var searchTitle: String { name }
    var searchSubtitle: String? { category.displayName }
    var searchBody: String { notes }
    var searchEntityType: LifeEntityType { .asset }
}

extension Subscription: SearchableRecord {
    var searchID: String { id.uuidString }
    var searchTitle: String { name }
    var searchSubtitle: String? { category.rawValue.capitalized }
    var searchBody: String { notes }
    var searchEntityType: LifeEntityType { .subscription }
}

extension Goal: SearchableRecord {
    var searchID: String { id.uuidString }
    var searchTitle: String { title }
    var searchSubtitle: String? { category.rawValue.capitalized }
    var searchBody: String { notes }
    var searchEntityType: LifeEntityType { .goal }
}

extension Moment: SearchableRecord {
    var searchID: String { id.uuidString }
    var searchTitle: String { title }
    var searchSubtitle: String? { category.displayName }
    var searchBody: String { summary }
    var searchEntityType: LifeEntityType { .moment }
}

extension NoteItem: SearchableRecord {
    var searchID: String { id.uuidString }
    var searchTitle: String { String(rawText.prefix(60)) }
    var searchSubtitle: String? { nil }
    var searchBody: String { "" }
    var searchEntityType: LifeEntityType { .note }
}
