import SwiftUI
import VisionKit

@MainActor
@Observable
final class AppModel {
    var screen: Screen = .title
    var mode: Mode = .summary
    var text = ""
    var result: SumResult?
    var error: String?
    var progress = 0.1
    var loadMessage = "CONNECTING TO AI..."
    var showScanner = false
    var showImporter = false
    var showPreview = false
    var showReader = false
    var pages: [UIImage] = []
    var docName: String?

    var showSettings = false
    var showHistory = false

    private var service: Summarizer {
        let cfg = AISettings.shared
        guard cfg.hasToken else { return MockSummarizer() }
        return LLMSummarizer(token: cfg.token.trimmingCharacters(in: .whitespacesAndNewlines),
                             model: cfg.model.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    var isDemo: Bool { !AISettings.shared.hasToken }

    func start() { if screen == .title { screen = .input } else if screen == .input { run() } }

    func a() {
        switch screen {
        case .title: screen = .input
        case .input: run()
        case .result: clearDocument(); screen = .input
        case .loading: break
        }
    }

    func b() {
        switch screen {
        case .input: clearDocument()
        case .result: screen = .input
        default: break
        }
    }

    func openCamera() {
        screen = .input
        guard VNDocumentCameraViewController.isSupported else { error = "NO CAMERA ON THIS DEVICE"; return }
        error = nil
        showScanner = true
    }

    func scanned(_ images: [UIImage]) {
        showScanner = false
        screen = .input
        Task {
            let found = await OCR.text(from: images)
            pages += images
            docName = docName == nil ? "SCAN" : "DOCUMENT"
            append(found, emptyMessage: "NO TEXT FOUND. TRY AGAIN.")
            showPreview = true
        }
    }

    func openFiles() { screen = .input; showImporter = true }

    func importFile(_ result: Result<[URL], Error>) {
        guard case .success(let urls) = result, let url = urls.first else { return }
        screen = .input
        Task {
            do {
                let doc = try await FileImport.load(url)
                pages += doc.pages
                docName = docName == nil ? doc.name : "DOCUMENT"
                append(doc.text, emptyMessage: "NO TEXT IN FILE")
                showPreview = true
            } catch {
                self.error = "CAN'T READ THAT FILE"
            }
        }
    }

    private func append(_ found: String, emptyMessage: String) {
        if found.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { error = emptyMessage; return }
        error = nil
        text = text.isEmpty ? found : text + "\n\n" + found
    }

    private func record(_ r: SumResult) {
        let flat = text.split(whereSeparator: \.isNewline).joined(separator: " ").trimmingCharacters(in: .whitespaces)
        let prefix = docName.map { $0 == "SCAN" ? "Scan · " : "\($0) · " } ?? ""
        HistoryStore.shared.add(HistoryEntry(title: prefix + String(flat.prefix(60)), mode: mode, result: r, demo: isDemo))
    }

    func clearDocument() { text = ""; pages = []; docName = nil; error = nil }

    func paste() {
        screen = .input
        if let s = UIPasteboard.general.string, !s.isEmpty { text = s; error = nil } else { error = "CLIPBOARD IS EMPTY" }
    }

    func handle(quickAction type: String) {
        if type == QuickAction.scan { openCamera() }
        else if type == QuickAction.paste { paste() }
        else if type == QuickAction.file { openFiles() }
        else if type == QuickAction.history { showHistory = true }
    }

    func select() { if screen == .input { mode = mode.next } }
    func selectPrev() { if screen == .input { mode = mode.prev } }

    func run() {
        guard text.trimmingCharacters(in: .whitespacesAndNewlines).count >= 20 else {
            error = "NEED MORE TEXT!"
            return
        }
        error = nil
        screen = .loading
        progress = 0.1
        let msgs = ["CONNECTING TO AI...", "READING TEXT...", "SUMMING IT UP...", "ALMOST DONE..."]
        loadMessage = msgs[0]
        Task {
            let ticker = Task {
                for i in 1...3 {
                    try? await Task.sleep(for: .seconds(0.4))
                    loadMessage = msgs[i]; progress = Double(i + 1) * 0.25
                }
            }
            do { let r = try await service.analyze(text, mode: mode); result = r; record(r) }
            catch { result = nil; self.error = error.localizedDescription.uppercased() }
            ticker.cancel()
            screen = .result
        }
    }
}
