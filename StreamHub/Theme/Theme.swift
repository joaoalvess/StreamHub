import SwiftUI

enum Theme {
    static let bg = Color(hex: 0x0B0A09)
    static let bgElevated = Color(hex: 0x15130F)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.6)
    static let textTertiary = Color.white.opacity(0.45)
    static let fill = Color.white
    static let fillOnDark = Color.white.opacity(0.15)
    static let cardStroke = Color.white.opacity(0.08)
    static let progressTrack = Color.white.opacity(0.25)
    static let progressFill = Color.white

    enum Font {
        static let sectionTitle = SwiftUI.Font.system(size: 30, weight: .semibold)
        static let heroTitle = SwiftUI.Font.system(size: 80, weight: .heavy)
        static let cardTitle = SwiftUI.Font.system(size: 26, weight: .semibold)
        static let meta = SwiftUI.Font.system(size: 24, weight: .regular)
        static let badge = SwiftUI.Font.system(size: 18, weight: .semibold)
    }

    enum Metrics {
        static let edgeH: CGFloat = 80
        static let rowSpacing: CGFloat = 44
        static let cardSpacing: CGFloat = 32
        static let titleGap: CGFloat = 16
        static let focusHeadroom: CGFloat = 60
    }

    enum Radius {
        static let card: CGFloat = 12
    }

    enum Size {
        static let posterHeight: CGFloat = 322     // tamanho único de card (Em alta == Top 10)
        static let posterWidth: CGFloat = 268      // ~4:5
        static let wideCardWidth: CGFloat = 380
        static let wideCardHeight: CGFloat = 214   // 16:9
    }

    static let heroGradientVertical = LinearGradient(
        colors: [.black.opacity(0.92), .clear],
        startPoint: .bottom,
        endPoint: .center
    )

    static let heroGradientHorizontal = LinearGradient(
        colors: [.black.opacity(0.75), .clear],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let backgroundGradient = LinearGradient(
        colors: [bg, bgElevated],
        startPoint: .top,
        endPoint: .bottom
    )

    // Sombreado interno na base do card para legibilidade do gênero.
    static let genreScrim = LinearGradient(
        colors: [.black.opacity(0.85), .clear],
        startPoint: .bottom,
        endPoint: UnitPoint(x: 0.5, y: 0.5)
    )

    // Fundo da Home que acompanha a tonalidade do hero atual (camada de tela).
    static func homeBackground(tint: Color) -> LinearGradient {
        LinearGradient(
            stops: [
                .init(color: tint, location: 0.0),
                .init(color: bg, location: 0.6)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// Borda translúcida estilo "liquid glass" revelada no foco dos cards.
struct LiquidGlassFocusBorder: ViewModifier {
    var isFocused: Bool
    var cornerRadius: CGFloat = Theme.Radius.card

    func body(content: Content) -> some View {
        content
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.85), .white.opacity(0.2), .white.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .opacity(isFocused ? 1 : 0)
            }
            .shadow(color: .white.opacity(isFocused ? 0.18 : 0), radius: 14)
            .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

extension View {
    func liquidGlassFocusBorder(_ isFocused: Bool, cornerRadius: CGFloat = Theme.Radius.card) -> some View {
        modifier(LiquidGlassFocusBorder(isFocused: isFocused, cornerRadius: cornerRadius))
    }
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}
