import SwiftUI

struct LCDView: View {
    @Bindable var model: AppModel
    @FocusState private var focused: Bool
    @State private var typed = ""
    @State private var blink = true
    @State private var scrollY = 0

    var body: some View {
        VStack(spacing: 0) {
            header
            Group {
                switch model.screen {
                case .title: title
                case .input: input
                case .loading: loading
                case .result: resultView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, minHeight: 230, maxHeight: .infinity)
        .background(Theme.lcd3)
        .overlay(pixelGrid.allowsHitTesting(false))
        .overlay(glare.allowsHitTesting(false))
        .overlay(Rectangle().stroke(Theme.lcd0, lineWidth: 3))
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .shadow(color: Theme.lcd0.opacity(0.5), radius: 0)
        .onChange(of: model.screen) { _, s in focused = (s == .input) }
        .onReceive(Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()) { _ in blink.toggle() }
    }

    // MARK: pieces

    private var header: some View {
        HStack {
            Text(["title": "SUM.IT", "input": "INPUT", "loading": "THINKING", "result": "RESULT"][name] ?? "")
            Spacer()
            Button { model.showSettings = true } label: {
                Text(model.screen == .loading ? "AI:BUSY" : (model.isDemo ? "AI:DEMO ⚙" : "AI:LLM ⚙"))
            }.buttonStyle(.plain)
        }
        .font(Theme.px(9)).foregroundStyle(Theme.lcd3)
        .padding(.horizontal, 8).padding(.vertical, 6)
        .background(Theme.lcd0)
    }
    private var name: String { "\(model.screen)" }

    private var title: some View {
        VStack(spacing: 14) {
            Text("∑").font(Theme.px(44)).foregroundStyle(Theme.lcd0)
                .offset(y: blink ? 0 : -4)
            Text("SUM.IT").font(Theme.px(34))
                .foregroundStyle(Theme.lcd0)
                .shadow(color: Theme.lcd2, radius: 0, x: 2, y: 2)
                .shadow(color: Theme.lcd1, radius: 0, x: 4, y: 4)
            Text("AI SUMMARY & ANALYSIS").font(Theme.px(8)).foregroundStyle(Theme.lcd1)
            Text("PRESS SUM").font(Theme.px(10)).foregroundStyle(Theme.lcd0).opacity(blink ? 1 : 0)
            if model.isDemo {
                Button { model.showSettings = true } label: {
                    Text("⚙ CONNECT AI").font(Theme.px(8)).foregroundStyle(Theme.lcd3)
                        .padding(.horizontal, 8).padding(.vertical, 4).background(Theme.lcd0)
                }.buttonStyle(.plain)
            }
            Text("©2026 SGL · v0.1 PROTOTYPE").font(Theme.px(7)).foregroundStyle(Theme.lcd1)
        }
        .foregroundStyle(Theme.lcd0)
    }

    private var input: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                ForEach(Mode.allCases, id: \.self) { m in
                    Text(m.rawValue).font(Theme.px(8))
                        .frame(maxWidth: .infinity).padding(.vertical, 5)
                        .foregroundStyle(model.mode == m ? Theme.lcd3 : Theme.lcd0)
                        .background(model.mode == m ? Theme.lcd0 : Theme.lcd3)
                        .overlay(Rectangle().stroke(Theme.lcd0, lineWidth: 2))
                        .onTapGesture { model.mode = m }
                }
            }
            if let name = model.docName {
                HStack {
                    Text("▤ " + name).lineLimit(1).truncationMode(.middle)
                    Spacer(minLength: 6)
                    Button { model.showPreview = true } label: { Text("VIEW").underline() }.buttonStyle(.plain)
                }.font(Theme.px(8)).foregroundStyle(Theme.lcd0)
            }
            ZStack(alignment: .topLeading) {
                TextEditor(text: $model.text)
                    .focused($focused)
                    .scrollContentBackground(.hidden)
                    .font(Theme.px(10, .bold)).foregroundStyle(Theme.lcd0)
                    .tint(Theme.lcd0)
                    .onChange(of: model.text) { _, _ in model.error = nil }
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Button("DONE") { focused = false }
                            Spacer()
                            Button("SUM IT ▶") { focused = false; model.run() }.bold()
                        }
                    }
                if model.text.isEmpty {
                    Text("PASTE TEXT OR ARTICLE HERE...\n\nTHEN PRESS SUM!")
                        .font(Theme.px(10, .bold)).foregroundStyle(Theme.lcd1)
                        .padding(8).allowsHitTesting(false)
                }
            }
            .background(Theme.lcd2)
            .overlay(Rectangle().stroke(Theme.lcd0, lineWidth: 2))
            HStack {
                Text(model.error ?? "\(model.text.count) CHARS").lineLimit(1).minimumScaleFactor(0.6)
                Spacer(minLength: 4)
                Button { model.openCamera() } label: {
                    Text("◉ SCAN").foregroundStyle(Theme.lcd3)
                        .padding(.horizontal, 6).padding(.vertical, 2).background(Theme.lcd0)
                }.buttonStyle(.plain)
                Button { model.openFiles() } label: {
                    Text("▤ FILE").foregroundStyle(Theme.lcd3)
                        .padding(.horizontal, 6).padding(.vertical, 2).background(Theme.lcd0)
                }.buttonStyle(.plain)
                Spacer(minLength: 4)
                Text("[BACK] CLEAR")
            }.font(Theme.px(8)).foregroundStyle(model.error == nil ? Theme.lcd1 : Theme.lcd0)
        }
        .padding(8)
    }

    private var loading: some View {
        VStack(spacing: 14) {
            Text("∑").font(Theme.px(40)).foregroundStyle(Theme.lcd0).rotationEffect(.degrees(blink ? -8 : 8))
            Text(model.loadMessage).font(Theme.px(10)).foregroundStyle(Theme.lcd0)
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Rectangle().stroke(Theme.lcd0, lineWidth: 2)
                    Rectangle().fill(Theme.lcd0)
                        .frame(width: (g.size.width - 6) * model.progress).padding(3)
                        .animation(.easeOut(duration: 0.25), value: model.progress)
                }
            }.frame(width: 210, height: 18)
        }
    }

    private var resultView: some View {
        VStack(spacing: 6) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 8) {
                    if let err = model.error, model.result == nil {
                        tag("ERROR"); body(err)
                    }
                    if let r = model.result {
                        if let s = r.summary {
                            tag("SUMMARY"); body(typed.isEmpty ? s : typed)
                            if !r.points.isEmpty {
                                tag("KEY POINTS")
                                ForEach(r.points, id: \.self) { body("▸ " + $0) }
                            }
                        }
                        if let l = r.sentimentLabel {
                            tag("ANALYSIS")
                            HStack { chip(l); if let sc = r.sentimentScore { chip("\(Int(sc * 100))%") } }
                        }
                        HStack { chip("\(r.words) WORDS"); chip("~\(r.readMinutes) MIN") }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(6)
            }
            .background(Theme.lcd2)
            .overlay(Rectangle().stroke(Theme.lcd0, lineWidth: 2))
            HStack {
                Text("▲▼ SCROLL")
                Spacer()
                Button { model.showReader = true } label: {
                    Text("▤ READ").foregroundStyle(Theme.lcd3)
                        .padding(.horizontal, 6).padding(.vertical, 2).background(Theme.lcd0)
                }.buttonStyle(.plain)
                Spacer()
                Text("[BACK] RETURN")
            }
                .font(Theme.px(8)).foregroundStyle(Theme.lcd1)
        }
        .padding(8)
        .task(id: model.result?.summary) { await typewrite() }
    }

    private func typewrite() async {
        typed = ""
        guard let s = model.result?.summary else { return }
        for ch in s {
            if Task.isCancelled { return }
            typed.append(ch)
            try? await Task.sleep(for: .milliseconds(18))
        }
    }

    private func tag(_ t: String) -> some View {
        Text(t).font(Theme.px(9)).foregroundStyle(Theme.lcd3)
            .padding(.horizontal, 5).padding(.vertical, 2).background(Theme.lcd0)
    }
    private func body(_ t: String) -> some View {
        Text(t).font(Theme.px(10, .bold)).foregroundStyle(Theme.lcd0).lineSpacing(4)
    }
    private func chip(_ t: String) -> some View {
        Text(t).font(Theme.px(8)).foregroundStyle(Theme.lcd0)
            .padding(.horizontal, 5).padding(.vertical, 2)
            .overlay(Rectangle().stroke(Theme.lcd0, lineWidth: 2))
    }

    // MARK: glass

    private var pixelGrid: some View {
        Canvas { ctx, size in
            var p = Path()
            stride(from: CGFloat(0), to: size.height, by: 3).forEach { y in p.addRect(CGRect(x: 0, y: y, width: size.width, height: 1)) }
            ctx.fill(p, with: .color(Theme.lcd0.opacity(0.07)))
        }
    }
    private var glare: some View {
        LinearGradient(colors: [.white.opacity(0.28), .clear], startPoint: .topLeading, endPoint: UnitPoint(x: 0.5, y: 0.45))
    }
}
