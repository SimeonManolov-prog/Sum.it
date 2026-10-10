import Foundation

struct HistoryEntry: Codable, Identifiable, Equatable {
    var id = UUID()
    var date = Date()
    var title: String
    var mode: Mode
    var result: SumResult
    var demo = false

    static func == (a: HistoryEntry, b: HistoryEntry) -> Bool { a.id == b.id }
}

struct DayCount: Identifiable {
    var id: Date
    var label: String
    var count: Int
}

struct ProgressStats {
    var total = 0
    var thisWeek = 0
    var goal = 5
    var streak = 0
    var words = 0
    var minutesSaved = 0
    var last7: [DayCount] = []
}

/// Saved analyses + progress, kept on-device as JSON. Only results are stored, not the source text.
@Observable
final class HistoryStore {
    static let shared = HistoryStore()
    private static let maxEntries = 500
    private static let readingWPM = 220.0

    private(set) var entries: [HistoryEntry] = []
    var weeklyGoal: Int {
        didSet { UserDefaults.standard.set(weeklyGoal, forKey: "history.weeklyGoal") }
    }

    private let url: URL

    private init() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        url = dir.appendingPathComponent("history.json")
        let g = UserDefaults.standard.integer(forKey: "history.weeklyGoal")
        weeklyGoal = g > 0 ? g : 5
        if let data = try? Data(contentsOf: url),
           let saved = try? JSONDecoder().decode([HistoryEntry].self, from: data) {
            entries = saved
        }
    }

    func add(_ entry: HistoryEntry) {
        entries.insert(entry, at: 0)
        if entries.count > Self.maxEntries { entries.removeLast(entries.count - Self.maxEntries) }
        save()
    }

    func delete(ids: [UUID]) {
        entries.removeAll { ids.contains($0.id) }
        save()
    }

    func clear() { entries = []; save() }

    private func save() {
        if let data = try? JSONEncoder().encode(entries) { try? data.write(to: url, options: .atomic) }
    }

    // MARK: progress

    var stats: ProgressStats {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let days = Set(entries.map { cal.startOfDay(for: $0.date) })

        var streak = 0
        var d = days.contains(today) ? today : cal.date(byAdding: .day, value: -1, to: today)!
        while days.contains(d) { streak += 1; d = cal.date(byAdding: .day, value: -1, to: d)! }

        let week = cal.dateInterval(of: .weekOfYear, for: .now)
        let thisWeek = entries.filter { week?.contains($0.date) ?? false }.count

        let saved = entries.reduce(0.0) { acc, e in
            guard let s = e.result.summary else { return acc }
            let original = Double(e.result.words) / Self.readingWPM
            let short = Double(s.split(whereSeparator: \.isWhitespace).count) / Self.readingWPM
            return acc + max(0, original - short)
        }

        let fmt = DateFormatter(); fmt.dateFormat = "EEEEE"
        let last7 = (0..<7).reversed().map { back -> DayCount in
            let day = cal.date(byAdding: .day, value: -back, to: today)!
            let n = entries.filter { cal.isDate($0.date, inSameDayAs: day) }.count
            return DayCount(id: day, label: fmt.string(from: day), count: n)
        }

        return ProgressStats(total: entries.count, thisWeek: thisWeek, goal: weeklyGoal, streak: streak,
                             words: entries.reduce(0) { $0 + $1.result.words },
                             minutesSaved: Int(saved.rounded()), last7: last7)
    }

    #if DEBUG
    /// Sample data for screenshots (`-seedHistory` launch argument).
    func seedDemo() {
        guard entries.isEmpty else { return }
        let samples: [(String, Int, Int, String, String)] = [
            ("Quarterly report · Revenue grew 12% on strong subscriptions", 0, 1800, "POSITIVE", "Revenue grew 12% year over year, driven by subscriptions. Costs stayed flat and the team plans two launches next quarter."),
            ("Scan · Terms of service update", 0, 950, "NEUTRAL", "The service updated its terms. Data retention is now 30 days and arbitration is required for disputes."),
            ("Research-paper.pdf · Sleep and memory consolidation", 1, 4200, "POSITIVE", "Sleep after learning improves recall. The effect was strongest for deep sleep and for factual material."),
            ("City council minutes · Transit budget", 2, 2600, "MIXED", "Council approved the transit budget with amendments. Bike lanes were delayed while bus frequency was increased."),
            ("Product launch email thread", 3, 700, "NEUTRAL", "The launch moved by a week. Marketing assets are ready and support training is scheduled."),
            ("Lecture notes · Thermodynamics", 5, 3100, "NEUTRAL", "Entropy measures disorder and always increases in isolated systems. Heat flows from hot to cold."),
        ]
        for (title, back, words, tone, sum) in samples {
            let date = Calendar.current.date(byAdding: .day, value: -back, to: .now)!.addingTimeInterval(-Double.random(in: 0...20_000))
            entries.append(HistoryEntry(date: date, title: title, mode: .both,
                result: SumResult(summary: sum, points: ["Main point one", "Main point two", "Main point three"],
                                  sentimentLabel: tone, sentimentScore: nil, words: words, readMinutes: max(1, words / 220))))
        }
        entries.sort { $0.date > $1.date }
        save()
    }
    #endif
}
