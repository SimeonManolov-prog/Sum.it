import UIKit
import PDFKit
import UniformTypeIdentifiers

struct ImportedDoc {
    var name: String
    var text: String
    var pages: [UIImage]
}

/// Reads PDFs, images, RTF and plain-text files. Scanned PDFs / images fall back to on-device OCR.
enum FileImport {
    static let types: [UTType] = [.pdf, .plainText, .text, .rtf, .image]

    static func load(_ url: URL) async throws -> ImportedDoc {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        let name = url.lastPathComponent
        let type = UTType(filenameExtension: url.pathExtension)

        if type?.conforms(to: .pdf) == true {
            return try await Task.detached { try await pdf(url, name) }.value
        }
        if type?.conforms(to: .image) == true {
            guard let image = UIImage(data: try Data(contentsOf: url)) else { throw CocoaError(.fileReadCorruptFile) }
            return ImportedDoc(name: name, text: await OCR.text(from: [image]), pages: [image])
        }
        if type?.conforms(to: .rtf) == true {
            let attr = try NSAttributedString(url: url, options: [.documentType: NSAttributedString.DocumentType.rtf], documentAttributes: nil)
            return ImportedDoc(name: name, text: attr.string, pages: [])
        }
        let data = try Data(contentsOf: url)
        let text = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) ?? ""
        return ImportedDoc(name: name, text: text, pages: [])
    }

    private static func pdf(_ url: URL, _ name: String) async throws -> ImportedDoc {
        guard let doc = PDFDocument(url: url) else { throw CocoaError(.fileReadCorruptFile) }
        let count = min(doc.pageCount, 12)
        let pages = (0..<count).compactMap { doc.page(at: $0)?.thumbnail(of: CGSize(width: 1000, height: 1400), for: .mediaBox) }
        var text = doc.string ?? ""
        if text.trimmingCharacters(in: .whitespacesAndNewlines).count < 20 {   // scanned PDF: no text layer
            text = await OCR.text(from: pages)
        }
        return ImportedDoc(name: name, text: text, pages: pages)
    }
}
