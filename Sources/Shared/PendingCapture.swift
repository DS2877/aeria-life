import Foundation

/// Something captured by the Share Extension, waiting for the main app to
/// turn it into a real `NoteItem` (and, eventually, a `DocumentRecord` if
/// it carries an image). The extension never touches SwiftData directly —
/// it runs in its own sandboxed process and can't reach the main app's
/// private on-disk store, so it drops a lightweight record here instead.
/// `PendingCaptureImporter` (Aeria-only) drains this on every launch.
///
/// `sourceKind` is a raw string, not `NoteSourceKind`, deliberately — that
/// enum lives in `Sources/Models`, which isn't shared with the extension.
/// The importer maps `"shareSheet"` back to `NoteSourceKind.shareSheet`.
struct PendingCapture: Codable, Identifiable {
    var id = UUID()
    var rawText: String
    var sourceKind: String
    /// Filename under `SharedStorage.containerURL`'s attachments directory,
    /// if this capture came with an image.
    var attachmentFileName: String?
    var createdAt = Date()
}

enum PendingCaptureQueue {
    private static let key = "aeria.pendingCaptures"

    static func append(_ capture: PendingCapture) {
        var all = readAll()
        all.append(capture)
        write(all)
    }

    /// Removes and returns everything queued — called once by the main app
    /// on launch. Whatever it fails to persist is lost, same tradeoff as
    /// any other "drain a queue" handoff; captures are meant to be acted on
    /// promptly, not held indefinitely in the extension's shadow storage.
    static func drainAll() -> [PendingCapture] {
        let all = readAll()
        write([])
        return all
    }

    static var attachmentsDirectory: URL? {
        guard let base = SharedStorage.containerURL else { return nil }
        let directory = base.appendingPathComponent("PendingCaptureAttachments", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private static func readAll() -> [PendingCapture] {
        guard let data = SharedStorage.defaults.data(forKey: key),
              let items = try? JSONDecoder().decode([PendingCapture].self, from: data) else {
            return []
        }
        return items
    }

    private static func write(_ items: [PendingCapture]) {
        guard let data = try? JSONEncoder().encode(items) else { return }
        SharedStorage.defaults.set(data, forKey: key)
    }
}
