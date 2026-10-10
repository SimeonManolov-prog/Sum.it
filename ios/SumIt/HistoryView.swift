import SwiftUI

/// Normal white screens: saved analyses and a progress dashboard.
struct HistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable private var store = HistoryStore.shared
    @State private var tab = CommandLine.arguments.contains("-openProgress") ? 1 : 0
    @State private var search = ""
    @State private var confirmClear = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("", selection: $tab) {
                    Text("History").tag(0)
                    Text("Progress").tag(1)
                }
                .pickerStyle(.segmented).padding()

                if tab == 0 { historyList } else { ProgressTab(store: store) }
            }
            .background(.white)
            .navigationTitle(tab == 0 ? "History" : "Progress")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
                if tab == 0 && !store.entries.isEmpty {
                    ToolbarItem(placement: .primaryAction) { Button("Clear all", role: .destructive) { confirmClear = true } }
                }
            }
            .confirmationDialog("Delete all saved summaries?", isPresented: $confirmClear, titleVisibility: .visible) {
                Button("Delete all", role: .destructive) { store.clear() }
            }
        }
    }

    private var filtered: [HistoryEntry] {
        guard !search.isEmpty else { return store.entries }
        return store.entries.filter {
            $0.title.localizedCaseInsensitiveContains(search) || ($0.result.summary ?? "").localizedCaseInsensitiveContains(search)
        }
    }

    @ViewBuilder private var historyList: some View {
        if store.entries.isEmpty {
            ContentUnavailableView("No summaries yet", systemImage: "clock.arrow.circlepath",
                                   description: Text("Everything you sum up will be saved here."))
        } else {
            List {
                ForEach(filtered) { entry in
                    NavigationLink { HistoryDetail(entry: entry) } label: { HistoryRow(entry: entry) }
                }
                .onDelete { offsets in store.delete(ids: offsets.map { filtered[$0].id }) }
            }
            .listStyle(.plain)
            .searchable(text: $search, prompt: "Search summaries")
        }
    }
}

private struct HistoryRow: View {
    let entry: HistoryEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(entry.title).font(.system(size: 16, weight: .semibold)).lineLimit(2)
            if let s = entry.result.summary {
                Text(s).font(.system(size: 14)).foregroundStyle(.secondary).lineLimit(2)
            }
            HStack(spacing: 6) {
                Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                Text("·"); Text("\(entry.result.words) words")
                if let t = entry.result.sentimentLabel { tag(t.capitalized, Theme.teal) }
                if entry.demo { tag("Demo", .gray) }
            }
            .font(.caption).foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
    private func tag(_ t: String, _ c: Color) -> some View {
        Text(t).font(.caption2.weight(.bold)).foregroundStyle(c)
            .padding(.horizontal, 6).padding(.vertical, 2).background(c.opacity(0.14), in: Capsule())
    }
}

struct HistoryDetail: View {
    let entry: HistoryEntry
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.title).font(.title3.weight(.bold))
                    Text(entry.date.formatted(date: .complete, time: .shortened)).font(.footnote).foregroundStyle(.secondary)
                }
                ResultBody(result: entry.result)
            }
            .frame(maxWidth: .infinity, alignment: .leading).padding(20)
        }
        .background(.white)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .primaryAction) { ShareLink(item: entry.result.shareText) } }
    }
}

// MARK: - progress

private struct ProgressTab: View {
    @Bindable var store: HistoryStore

    var body: some View {
        let s = store.stats
        ScrollView {
            VStack(spacing: 16) {
                goalCard(s)
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible())], spacing: 12) {
                    stat("\(s.total)", "Summaries", "text.alignleft")
                    stat("\(s.streak)", s.streak == 1 ? "Day streak" : "Day streak", "flame.fill")
                    stat(s.words.formatted(), "Words read", "book.fill")
                    stat(timeString(s.minutesSaved), "Time saved", "clock.fill")
                }
                weekChart(s)
                Text("Time saved compares the original reading time with the summary, at about 220 words per minute.")
                    .font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
            }
            .padding()
        }
    }

    private func goalCard(_ s: ProgressStats) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("THIS WEEK").font(Theme.px(10)).foregroundStyle(Theme.label)
                Spacer()
                Text("\(s.thisWeek) / \(s.goal)").font(Theme.px(12)).foregroundStyle(Theme.accent)
            }
            ProgressView(value: min(1, Double(s.thisWeek) / Double(max(1, s.goal))))
                .tint(s.thisWeek >= s.goal ? .green : Theme.accent)
            Text(s.thisWeek >= s.goal ? "Weekly goal reached. Nice work!" : "\(s.goal - s.thisWeek) more to hit your weekly goal.")
                .font(.footnote).foregroundStyle(.secondary)
            Stepper("Weekly goal: \(store.weeklyGoal)", value: $store.weeklyGoal, in: 1...50)
                .font(.subheadline)
        }
        .padding(16)
        .background(Color(red: 0.94, green: 0.93, blue: 1.0), in: RoundedRectangle(cornerRadius: 16))
    }

    private func stat(_ value: String, _ label: String, _ icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon).foregroundStyle(Theme.teal)
            Text(value).font(Theme.px(20)).foregroundStyle(Theme.lcd0).minimumScaleFactor(0.6).lineLimit(1)
            Text(label).font(.footnote).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(14)
        .background(Color(white: 0.96), in: RoundedRectangle(cornerRadius: 16))
    }

    private func weekChart(_ s: ProgressStats) -> some View {
        let top = max(1, s.last7.map(\.count).max() ?? 1)
        return VStack(alignment: .leading, spacing: 12) {
            Text("LAST 7 DAYS").font(Theme.px(10)).foregroundStyle(Theme.label)
            HStack(alignment: .bottom, spacing: 10) {
                ForEach(s.last7) { d in
                    VStack(spacing: 6) {
                        Text(d.count > 0 ? "\(d.count)" : " ").font(.caption2.weight(.bold)).foregroundStyle(.secondary)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(d.count > 0 ? Theme.accent : Color(white: 0.88))
                            .frame(height: max(6, CGFloat(d.count) / CGFloat(top) * 90))
                        Text(d.label).font(.caption2).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .bottom)
                }
            }
            .frame(height: 130, alignment: .bottom)
        }
        .padding(16)
        .background(Color(white: 0.96), in: RoundedRectangle(cornerRadius: 16))
    }

    private func timeString(_ minutes: Int) -> String {
        minutes >= 60 ? "\(minutes / 60)h \(minutes % 60)m" : "\(minutes)m"
    }
}
