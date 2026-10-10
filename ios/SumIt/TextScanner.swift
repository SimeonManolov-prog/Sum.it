import SwiftUI
import VisionKit
import Vision

/// Wraps Apple's document camera so the user can photograph a page, sign, or screen.
struct DocumentScanner: UIViewControllerRepresentable {
    var onFinish: ([UIImage]) -> Void
    var onCancel: () -> Void

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let vc = VNDocumentCameraViewController()
        vc.delegate = context.coordinator
        return vc
    }
    func updateUIViewController(_ vc: VNDocumentCameraViewController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let parent: DocumentScanner
        init(_ parent: DocumentScanner) { self.parent = parent }

        func documentCameraViewController(_ c: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            parent.onFinish((0..<scan.pageCount).map { scan.imageOfPage(at: $0) })
        }
        func documentCameraViewControllerDidCancel(_ c: VNDocumentCameraViewController) { parent.onCancel() }
        func documentCameraViewController(_ c: VNDocumentCameraViewController, didFailWithError error: Error) { parent.onCancel() }
    }
}

/// On-device OCR: turns scanned pages into plain text.
enum OCR {
    static func text(from images: [UIImage]) async -> String {
        await Task.detached(priority: .userInitiated) {
            var pages: [String] = []
            for image in images {
                guard let cg = image.cgImage else { continue }
                let request = VNRecognizeTextRequest()
                request.recognitionLevel = .accurate
                request.usesLanguageCorrection = true
                try? VNImageRequestHandler(cgImage: cg).perform([request])
                let lines = (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }
                pages.append(lines.joined(separator: " "))
            }
            return pages.joined(separator: "\n\n")
        }.value
    }
}
