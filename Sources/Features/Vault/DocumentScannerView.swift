import CoreGraphics
import SwiftUI
import VisionKit

/// Thin UIKit bridge to `VNDocumentCameraViewController` — Apple's own
/// document scanner (auto edge detection, perspective correction). Camera
/// scanning only works on a real device, not the Simulator; see
/// SETUP-MAC.md for how to test this on a physical iPhone.
struct DocumentScannerView: UIViewControllerRepresentable {
    var onScan: (CGImage) -> Void
    var onCancel: () -> Void

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let controller = VNDocumentCameraViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onScan: onScan, onCancel: onCancel)
    }

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let onScan: (CGImage) -> Void
        let onCancel: () -> Void

        init(onScan: @escaping (CGImage) -> Void, onCancel: @escaping () -> Void) {
            self.onScan = onScan
            self.onCancel = onCancel
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFinishWith scan: VNDocumentCameraScan
        ) {
            guard scan.pageCount > 0, let cgImage = scan.imageOfPage(at: 0).cgImage else {
                onCancel()
                return
            }
            onScan(cgImage)
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            onCancel()
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            onCancel()
        }
    }
}
