import SwiftUI

/// Normal (non-LCD) view of the scanned / imported document, with editable extracted text.
struct DocumentPreview: View {
    @Bindable var model: AppModel
    @State private var tab = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !model.pages.isEmpty {
                    Picker("", selection: $tab) {
                        Text("Pages").tag(0)
                        Text("Text").tag(1)
                    }
                    .pickerStyle(.segmented).padding()
                }
                if tab == 0 && !model.pages.isEmpty {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(Array(model.pages.enumerated()), id: \.offset) { _, img in
                                Image(uiImage: img).resizable().scaledToFit()
                                    .background(.white)
                                    .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
                            }
                        }
                        .padding()
                    }
                    .background(Color(white: 0.94))
                } else {
                    TextEditor(text: $model.text)
                        .padding(.horizontal)
                        .background(.white)
                        .overlay(alignment: .topLeading) {
                            if model.text.isEmpty { Text("No text found.").foregroundStyle(.secondary).padding(.horizontal, 21).padding(.top, 8) }
                        }
                }
            }
            .background(.white)
            .navigationTitle(model.docName ?? "Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { model.showPreview = false } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Sum it") { model.showPreview = false; model.run() }.bold()
                        .disabled(model.text.trimmingCharacters(in: .whitespacesAndNewlines).count < 20)
                }
            }
        }
    }
}

extension SumResult {
    var shareText: String {
        var t = ""
        if let sum = summary { t += "Summary\n\(sum)\n\n" }
        if !points.isEmpty { t += "Key points\n" + points.map { "• \($0)" }.joined(separator: "\n") }
        if let tone = sentimentLabel { t += "\n\nTone: \(tone.capitalized)" }
        return t
    }
}

/// The result laid out for comfortable reading (shared by the reader and the history detail).
struct ResultBody: View {
    let result: SumResult

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let s = result.summary {
                section("Summary") { Text(s).font(.system(size: 19, design: .serif)).lineSpacing(5) }
                if !result.points.isEmpty {
                    section("Key points") {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(result.points, id: \.self) { Label($0, systemImage: "circle.fill").labelStyle(BulletStyle()) }
                        }
                    }
                }
            }
            if let l = result.sentimentLabel {
                section("Tone") {
                    Text(result.sentimentScore.map { "\(l.capitalized) · \(Int($0 * 100))% confidence" } ?? l.capitalized).font(.body)
                }
            }
            Text("\(result.words) words · about \(result.readMinutes) min read").font(.footnote).foregroundStyle(.secondary)
        }
    }

    private func section<C: View>(_ title: String, @ViewBuilder _ content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased()).font(.caption.weight(.bold)).foregroundStyle(Theme.accent)
            content()
        }
    }
}

/// Normal white reading view of the latest result — easier on the eyes than the LCD for longer text.
struct ResultReader: View {
    @Bindable var model: AppModel

    var body: some View {
        NavigationStack {
            ScrollView {
                Group {
                    if let r = model.result { ResultBody(result: r) }
                    else if let e = model.error { Text(e.capitalized).foregroundStyle(.secondary) }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
            }
            .background(.white)
            .navigationTitle("Result")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Done") { model.showReader = false } }
                ToolbarItem(placement: .primaryAction) { ShareLink(item: model.result?.shareText ?? "") }
            }
        }
    }
}

private struct BulletStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            configuration.icon.font(.system(size: 6)).foregroundStyle(Theme.accent)
            configuration.title.font(.system(size: 17))
        }
    }
}
