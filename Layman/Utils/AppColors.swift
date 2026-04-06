import SwiftUI

// MARK: - AppColors

enum AppColors {

    // Gradients
    static let gradientTop    = Color(hex: "#F4845F")   // warm orange
    static let gradientMid    = Color(hex: "#FFF8F3")   // near-white cream centre
    static let gradientBottom = Color(hex: "#F4845F")   // warm orange

    static let welcomeGradient = LinearGradient(
        colors: [gradientTop, gradientMid, gradientBottom],
        startPoint: .top,
        endPoint: .bottom
    )

    // Accent
    static let accentOrange   = Color(hex: "#CC6130")   // "made simple" / buttons
    static let accentLight    = Color(hex: "#F5956E")   // lighter accent

    // Backgrounds
    static let backgroundCream = Color(hex: "#FBF5F0")  // main app background
    static let cardBackground  = Color(hex: "#FFFFFF")
    static let cardSurface     = Color(hex: "#F8F0E8")  // content card background

    // Text
    static let textPrimary     = Color(hex: "#1A1A1A")
    static let textSecondary   = Color(hex: "#6B6B6B")
    static let textTertiary    = Color(hex: "#9B9B9B")

    // Tab bar
    static let tabBarBackground = Color(hex: "#FFFFFF")
    static let tabBarSelected   = accentOrange
    static let tabBarUnselected = Color(hex: "#BBBBBB")
}

// MARK: - AppFonts

enum AppFonts {
    // Headings — SF Pro Bold for the "Layman" brand
    static func logo(size: CGFloat = 32) -> Font {
        .system(size: size, weight: .bold)
    }

    static func headline(size: CGFloat = 20) -> Font {
        .system(size: size, weight: .bold, design: .default)
    }

    static func subheadline(size: CGFloat = 15) -> Font {
        .system(size: size, weight: .semibold, design: .default)
    }

    static func body(size: CGFloat = 15) -> Font {
        .system(size: size, weight: .regular, design: .default)
    }

    static func caption(size: CGFloat = 12) -> Font {
        .system(size: size, weight: .regular, design: .default)
    }

    static func button(size: CGFloat = 15) -> Font {
        .system(size: size, weight: .semibold, design: .default)
    }
}

// MARK: - Color Hex Init

extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch cleaned.count {
        case 3:
            (a, r, g, b) = (255,
                            (int >> 8) * 17,
                            (int >> 4 & 0xF) * 17,
                            (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255,
                            int >> 16,
                            int >> 8 & 0xFF,
                            int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24,
                            int >> 16 & 0xFF,
                            int >> 8 & 0xFF,
                            int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
