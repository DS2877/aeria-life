import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// Master prompt § 76 Share Sheet: accept text, a link, an image, or a PDF
/// from any app, let the user glance at what Aeria captured, and queue it
/// for the main app to file (see `Sources/Shared/PendingCapture.swift` for
/// why this doesn't touch SwiftData directly).
///
/// Programmatic `UIViewController` hosting a SwiftUI review screen, rather
/// than a storyboard — `NSExtensionPrincipalClass` in project.yml points
/// straight at this class.
final class ShareViewController: UIViewController {
    private struct Attachment {
        let data: Data
        let fileExtension: String
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        Task { await loadAndPresent() }
    }

    private func loadAndPresent() async {
        let (text, attachment) = await extractContent()
        let review = ShareReviewView(
            initialText: text,
            hasImage: attachment != nil,
            onSave: { [weak self] finalText in
                self?.save(text: finalText, attachment: attachment)
            },
            onCancel: { [weak self] in
                self?.close()
            }
        )
        let hosting = UIHostingController(rootView: review)
        hosting.view.backgroundColor = .clear
        addChild(hosting)
        view.addSubview(hosting.view)
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hosting.view.topAnchor.constraint(equalTo: view.topAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        hosting.didMove(toParent: self)
    }

    private func extractContent() async -> (text: String, attachment: Attachment?) {
        guard let item = extensionContext?.inputItems.first as? NSExtensionItem,
              let attachments = item.attachments else {
            return ("", nil)
        }

        var text = ""
        var attachment: Attachment?

        for provider in attachments {
            if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                if let loaded = await loadItem(provider, typeIdentifier: UTType.plainText.identifier) as? String {
                    text += (text.isEmpty ? "" : "\n") + loaded
                }
            } else if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                if let url = await loadItem(provider, typeIdentifier: UTType.url.identifier) as? URL {
                    text += (text.isEmpty ? "" : "\n") + url.absoluteString
                }
            } else if provider.hasItemConformingToTypeIdentifier(UTType.pdf.identifier) {
                if let loaded = await loadItem(provider, typeIdentifier: UTType.pdf.identifier),
                   let data = dataFrom(loaded) {
                    attachment = Attachment(data: data, fileExtension: "pdf")
                }
            } else if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                if let loaded = await loadItem(provider, typeIdentifier: UTType.image.identifier),
                   let data = imageDataFrom(loaded) {
                    attachment = Attachment(data: data, fileExtension: "jpg")
                }
            }
        }
        return (text, attachment)
    }

    /// Wraps the completion-handler `NSItemProvider.loadItem` — the
    /// long-stable API, rather than gambling on an async overload's exact
    /// availability in an environment this couldn't be compiled in.
    private func loadItem(_ provider: NSItemProvider, typeIdentifier: String) async -> NSSecureCoding? {
        await withCheckedContinuation { (continuation: CheckedContinuation<NSSecureCoding?, Never>) in
            provider.loadItem(forTypeIdentifier: typeIdentifier, options: nil) { item, _ in
                continuation.resume(returning: item)
            }
        }
    }

    private func dataFrom(_ item: NSSecureCoding) -> Data? {
        if let url = item as? URL {
            return try? Data(contentsOf: url)
        }
        return item as? Data
    }

    private func imageDataFrom(_ item: NSSecureCoding) -> Data? {
        if let image = item as? UIImage {
            return image.jpegData(compressionQuality: 0.85)
        }
        return dataFrom(item)
    }

    private func save(text: String, attachment: Attachment?) {
        var attachmentFileName: String?
        if let attachment, let directory = PendingCaptureQueue.attachmentsDirectory {
            let fileName = "\(UUID().uuidString).\(attachment.fileExtension)"
            try? attachment.data.write(to: directory.appendingPathComponent(fileName))
            attachmentFileName = fileName
        }

        PendingCaptureQueue.append(PendingCapture(
            rawText: text,
            sourceKind: "shareSheet",
            attachmentFileName: attachmentFileName
        ))
        close()
    }

    private func close() {
        extensionContext?.completeRequest(returningItems: nil)
    }
}
