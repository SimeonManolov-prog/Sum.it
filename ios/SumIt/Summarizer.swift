import Foundation
import NaturalLanguage

protocol Summarizer {
    func analyze(_ text: String, mode: Mode) async throws -> SumResult
}

/// Splits text into sentences on-device (used for key points and the demo fallback).
func sentences(in text: String) -> [String] {
    let t = NLTokenizer(unit: .sentence)
    t.string = text
    return t.tokens(for: text.startIndex..<text.endIndex)
        .map { String(text[$0]).trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
}

func basics(_ text: String) -> (words: Int, mins: Int, points: [String]) {
    let words = text.split(whereSeparator: \.isWhitespace).count
    let points = sentences(in: text).prefix(4).map { s -> String in
        let w = s.split(separator: " ")
        return w.count > 9 ? w.prefix(9).joined(separator: " ") + "…" : s
    }
    return (words, max(1, Int((Double(words) / 220).rounded())), Array(points))
}

// MARK: - Demo (no token needed)

struct MockSummarizer: Summarizer {
    func analyze(_ text: String, mode: Mode) async throws -> SumResult {
        try await Task.sleep(for: .seconds(1.4))
        let b = basics(text)
        let neg = text.range(of: #"\b(bad|worse|fail|loss|problem|sad)\b"#, options: [.regularExpression, .caseInsensitive]) != nil
        return SumResult(
            summary: mode == .analysis ? nil : sentences(in: text).prefix(2).joined(separator: " "),
            points: b.points,
            sentimentLabel: mode == .summary ? nil : (neg ? "NEGATIVE" : "POSITIVE"),
            sentimentScore: mode == .summary ? nil : 0.6 + Double.random(in: 0...0.35),
            words: b.words, readMinutes: b.mins)
    }
}

enum SumError: LocalizedError {
    case http(Int)
    case badOutput

    var errorDescription: String? {
        switch self {
        case .badOutput: return "AI SENT AN UNREADABLE REPLY."
        case .http(401), .http(403): return "BAD TOKEN OR NO ACCESS. CHECK SETTINGS."
        case .http(402): return "OUT OF HUGGINGFACE CREDITS."
        case .http(400), .http(404): return "MODEL NOT AVAILABLE. TRY ANOTHER."
        case .http(429): return "RATE LIMITED. WAIT A MOMENT."
        case .http(503): return "MODEL IS WARMING UP. TRY AGAIN."
        case .http(let c): return "SERVER ERROR \(c)."
        }
    }
}
