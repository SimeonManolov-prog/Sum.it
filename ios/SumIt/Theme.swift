import SwiftUI

/// Sum.it's own look: indigo "ink on lavender paper" pixel screen, navy frame, coral hero key.
enum Theme {
    // Screen palette (0 = darkest ink … 3 = lightest paper)
    static let lcd0 = Color(red: 0.13, green: 0.11, blue: 0.35)
    static let lcd1 = Color(red: 0.33, green: 0.30, blue: 0.62)
    static let lcd2 = Color(red: 0.84, green: 0.83, blue: 0.96)
    static let lcd3 = Color(red: 0.94, green: 0.93, blue: 1.00)

    static let frameHi = Color(red: 0.22, green: 0.25, blue: 0.48)
    static let frame = Color(red: 0.12, green: 0.14, blue: 0.30)
    static let frameLo = Color(red: 0.07, green: 0.08, blue: 0.19)

    static let accent = Color(red: 0.93, green: 0.33, blue: 0.20)
    static let accentHi = Color(red: 1.00, green: 0.66, blue: 0.48)
    static let teal = Color(red: 0.16, green: 0.62, blue: 0.68)
    static let label = Color(red: 0.18, green: 0.20, blue: 0.50)

    static func px(_ size: CGFloat, _ weight: Font.Weight = .heavy) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}
