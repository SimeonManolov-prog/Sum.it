import SwiftUI

/// The whole screen is the device: white pearl body, navy frame + paper-ink pixel screen, and a
/// row of function keys with one big coral SUM key. (Original layout — not a clone of any console.)
struct ContentView: View {
    @State private var model = AppModel()

    var body: some View {
        ZStack {
            shell.ignoresSafeArea()
            VStack(spacing: 0) {
                topRail
                screenFrame
                brand
                controls
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 12)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .fullScreenCover(isPresented: $model.showScanner) {
            DocumentScanner(onFinish: model.scanned, onCancel: { model.showScanner = false })
                .ignoresSafeArea()
        }
        .sheet(isPresented: $model.showPreview) { DocumentPreview(model: model) }
        .sheet(isPresented: $model.showSettings) { SettingsView() }
        .sheet(isPresented: $model.showHistory) { HistoryView() }
        .sheet(isPresented: $model.showReader) { ResultReader(model: model) }
        .fileImporter(isPresented: $model.showImporter, allowedContentTypes: FileImport.types,
                      onCompletion: { model.importFile($0.map { [$0] }) })
        .onAppear {
            #if DEBUG
            if CommandLine.arguments.contains("-seedHistory") { HistoryStore.shared.seedDemo() }
            if CommandLine.arguments.contains("-openHistory") { model.showHistory = true }
            #endif
            if let t = QuickAction.pending { QuickAction.pending = nil; model.handle(quickAction: t) }
        }
        .onReceive(NotificationCenter.default.publisher(for: QuickAction.didFire)) { n in
            if let t = n.object as? String { model.handle(quickAction: t) }
        }
    }

    // MARK: body

    private var shell: some View {
        ZStack {
            LinearGradient(colors: [.white, Color(red: 0.96, green: 0.95, blue: 0.99), Color(red: 0.89, green: 0.88, blue: 0.96)],
                           startPoint: .top, endPoint: .bottom)
            LinearGradient(colors: [.clear, .white.opacity(0.9), .clear],
                           startPoint: UnitPoint(x: 0, y: 0.1), endPoint: UnitPoint(x: 0.9, y: 0.45))
                .blendMode(.plusLighter)
        }
    }

    private var topRail: some View {
        HStack {
            Text("SUM.IT · POCKET AI"); Spacer(); Text("STELLAR GALAXY LABS")
        }
        .font(Theme.px(7, .bold)).foregroundStyle(Color(white: 0.58))
        .padding(.vertical, 8)
    }

    // MARK: screen

    private var screenFrame: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Text("Σ").font(Theme.px(12)).foregroundStyle(Theme.lcd2)
                Capsule().fill(Theme.teal.opacity(0.9)).frame(height: 3)
                Circle().fill(Theme.teal).frame(width: 7, height: 7)
                    .shadow(color: Theme.teal, radius: 4)
            }
            LCDView(model: model)
        }
        .padding(.horizontal, 14).padding(.top, 10).padding(.bottom, 14)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(LinearGradient(colors: [Theme.frameHi, Theme.frame, Theme.frameLo], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(RoundedRectangle(cornerRadius: 28).stroke(.white.opacity(0.22), lineWidth: 1))
                .shadow(color: Color(red: 0.45, green: 0.45, blue: 0.68), radius: 0, y: 4)
                .shadow(color: .black.opacity(0.25), radius: 14, y: 14)
        )
    }

    private var brand: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("sum.it").font(.system(size: 22, weight: .black, design: .rounded)).foregroundStyle(Theme.label)
            Text("PIXEL SUMMARIES").font(Theme.px(8, .bold)).foregroundStyle(Color(white: 0.5))
        }
        .padding(.vertical, 12)
    }

    // MARK: controls

    private var controls: some View {
        VStack(spacing: 22) {
            HStack(spacing: 12) {
                KeyButton(title: "SCAN", icon: "camera.viewfinder", action: model.openCamera)
                KeyButton(title: "FILE", icon: "doc.badge.plus", action: model.openFiles)
                KeyButton(title: "LOG", icon: "clock.arrow.circlepath", action: { model.showHistory = true })
                KeyButton(title: "BACK", icon: "arrow.uturn.backward", action: model.b)
            }
            HStack(alignment: .center) {
                Rocker(onLeft: model.selectPrev, onRight: model.select)
                Spacer()
                SumButton(action: model.a)
            }
            .padding(.horizontal, 4)
        }
    }
}
