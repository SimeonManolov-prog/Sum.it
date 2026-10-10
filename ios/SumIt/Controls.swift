import SwiftUI

/// Presses down in 3D when touched.
struct PressStyle: ButtonStyle {
    var depth: CGFloat
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .offset(y: configuration.isPressed ? depth - 1 : 0)
            .animation(.linear(duration: 0.04), value: configuration.isPressed)
    }
}

/// The big coral hero key: starts, summarizes, and begins again.
struct SumButton: View {
    let action: () -> Void
    var body: some View {
        VStack(spacing: 8) {
            Button { Haptics.tap(); action() } label: {
                ZStack {
                    Circle().fill(RadialGradient(
                        colors: [Theme.accentHi, Theme.accent, Color(red: 0.62, green: 0.16, blue: 0.09)],
                        center: UnitPoint(x: 0.35, y: 0.25), startRadius: 0, endRadius: 80))
                    Circle().fill(LinearGradient(colors: [.white.opacity(0.55), .clear], startPoint: .top, endPoint: UnitPoint(x: 0.5, y: 0.5)))
                        .padding(8)
                    VStack(spacing: 0) {
                        Text("Σ").font(Theme.px(34))
                        Text("SUM").font(Theme.px(11))
                    }
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.22), radius: 0, y: 1)
                }
                .frame(width: 104, height: 104)
                .shadow(color: Color(red: 0.45, green: 0.10, blue: 0.05), radius: 0, y: 7)
                .shadow(color: .black.opacity(0.35), radius: 8, y: 12)
            }
            .buttonStyle(PressStyle(depth: 6))
        }
    }
}

/// Glossy square function key (SCAN / FILE / BACK).
struct KeyButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    var body: some View {
        Button { Haptics.tap(); action() } label: {
            VStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 18, weight: .bold))
                Text(title).font(Theme.px(9))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity).frame(height: 58)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(LinearGradient(colors: [Color(red: 0.42, green: 0.80, blue: 0.84), Theme.teal, Color(red: 0.08, green: 0.38, blue: 0.44)],
                                         startPoint: .top, endPoint: .bottom))
                    .overlay(alignment: .top) {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(LinearGradient(colors: [.white.opacity(0.45), .clear], startPoint: .top, endPoint: .bottom))
                            .frame(height: 26).padding(2)
                    }
                    .shadow(color: Color(red: 0.05, green: 0.25, blue: 0.30), radius: 0, y: 5)
                    .shadow(color: .black.opacity(0.25), radius: 6, y: 9)
            )
        }
        .buttonStyle(PressStyle(depth: 4))
    }
}

/// Horizontal rocker that switches mode (Summary / Analysis / Both).
struct Rocker: View {
    let onLeft: () -> Void
    let onRight: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 0) {
                half("chevron.left", onLeft)
                Rectangle().fill(.white.opacity(0.18)).frame(width: 1, height: 28)
                half("chevron.right", onRight)
            }
            .frame(width: 148, height: 52)
            .background(
                Capsule()
                    .fill(LinearGradient(colors: [Theme.frameHi, Theme.frame, Theme.frameLo], startPoint: .top, endPoint: .bottom))
                    .overlay(Capsule().stroke(.white.opacity(0.25), lineWidth: 1))
                    .shadow(color: Color(red: 0.03, green: 0.04, blue: 0.12), radius: 0, y: 5)
                    .shadow(color: .black.opacity(0.3), radius: 6, y: 9)
            )
            Text("MODE").font(Theme.px(9)).foregroundStyle(Theme.label)
        }
    }

    private func half(_ icon: String, _ action: @escaping () -> Void) -> some View {
        Button { Haptics.tap(); action() } label: {
            Image(systemName: icon).font(.system(size: 18, weight: .heavy)).foregroundStyle(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity).contentShape(Rectangle())
        }
        .buttonStyle(PressStyle(depth: 3))
    }
}

enum Haptics {
    static func tap() { UIImpactFeedbackGenerator(style: .rigid).impactOccurred() }
}
