import Foundation

enum Screen { case title, input, loading, result }

enum Mode: String, CaseIterable, Codable {
    case summary = "SUMMARY", analysis = "ANALYSIS", both = "BOTH"
    var prev: Mode {
        let all = Mode.allCases
        return all[(all.firstIndex(of: self)! + all.count - 1) % all.count]
    }
    var next: Mode {
        let all = Mode.allCases
        return all[(all.firstIndex(of: self)! + 1) % all.count]
    }
}

struct SumResult: Codable {
    var summary: String?
    var points: [String] = []
    var sentimentLabel: String?
    var sentimentScore: Double?
    var words: Int
    var readMinutes: Int
}
