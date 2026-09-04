import Foundation
import SwiftData

enum NoteSourceKind: String, Codable, CaseIterable, Hashable {
    case text, voice, photo, link, document, shareSheet
}

/// The Life Inbox landing spot — master prompt § 74. Anything the user
/// captures arrives here first, unsorted, before Aeria (or the user) decides
/// where it belongs. This is deliberately the *only* required step to
/// capture something; sorting happens after, asynchronously.
@Model
final class NoteItem {
    @Attribute(.unique) var id: UUID
    var rawText: String
    var sourceKind: NoteSourceKind
    /// Filename under app storage, if this came with an image/document.
    var attachmentFileName: String?
    var isProcessed: Bool
    /// Once Aeria (or the user) files this into another entity, record what
    /// it became so the inbox item can be hidden without being deleted.
    var resultingEntityType: LifeEntityType?
    var resultingEntityID: String?
    var provenance: Provenance
    var createdAt: Date
    var updatedAt: Date

    init(
        rawText: String,
        sourceKind: NoteSourceKind = .text,
        attachmentFileName: String? = nil,
        provenance: Provenance = .userProvided,
        createdAt: Date = .now
    ) {
        self.id = UUID()
        self.rawText = rawText
        self.sourceKind = sourceKind
        self.attachmentFileName = attachmentFileName
        self.isProcessed = false
        self.resultingEntityType = nil
        self.resultingEntityID = nil
        self.provenance = provenance
        self.createdAt = createdAt
        self.updatedAt = createdAt
    }
}
