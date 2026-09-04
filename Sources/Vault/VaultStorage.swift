import Foundation

/// Where Vault document/asset binaries live on disk — deliberately outside
/// SwiftData (see PersistenceController's header comment on why blobs stay
/// out of the store). `Application Support` rather than `Documents` since
/// this isn't meant to be user-visible in the Files app.
enum VaultStorage {
    static var directoryURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let vault = base.appendingPathComponent("Vault", isDirectory: true)
        if !FileManager.default.fileExists(atPath: vault.path) {
            try? FileManager.default.createDirectory(at: vault, withIntermediateDirectories: true)
        }
        return vault
    }

    static func url(for fileName: String) -> URL {
        directoryURL.appendingPathComponent(fileName)
    }

    @discardableResult
    static func save(data: Data, suggestedExtension: String) throws -> String {
        let fileName = "\(UUID().uuidString).\(suggestedExtension)"
        try data.write(to: url(for: fileName), options: .atomic)
        return fileName
    }

    static func delete(fileName: String) {
        try? FileManager.default.removeItem(at: url(for: fileName))
    }
}
