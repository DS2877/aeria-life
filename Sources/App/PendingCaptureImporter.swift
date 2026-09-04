import Foundation
import SwiftData

/// The main app's half of the Share Extension handoff (see
/// `Sources/Shared/PendingCapture.swift`): turns whatever the extension
/// queued into real `NoteItem`s, copying any attachment out of the App
/// Group's shared container and into the app's own Vault storage.
@MainActor
enum PendingCaptureImporter {
    static func importPending(into context: ModelContext) {
        let pending = PendingCaptureQueue.drainAll()
        guard !pending.isEmpty else { return }

        for capture in pending {
            var importedAttachmentFileName: String?
            if let sourceFileName = capture.attachmentFileName,
               let sourceDirectory = PendingCaptureQueue.attachmentsDirectory {
                let sourceURL = sourceDirectory.appendingPathComponent(sourceFileName)
                if let data = try? Data(contentsOf: sourceURL) {
                    let ext = (sourceFileName as NSString).pathExtension
                    importedAttachmentFileName = try? VaultStorage.save(
                        data: data,
                        suggestedExtension: ext.isEmpty ? "dat" : ext
                    )
                }
                try? FileManager.default.removeItem(at: sourceURL)
            }

            context.insert(NoteItem(
                rawText: capture.rawText,
                sourceKind: NoteSourceKind(rawValue: capture.sourceKind) ?? .shareSheet,
                attachmentFileName: importedAttachmentFileName,
                provenance: .userProvided,
                createdAt: capture.createdAt
            ))
        }
    }
}
