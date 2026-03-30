import SwiftUI

struct SL {
    // MARK: - Colors
    static let background = Color(hex: "FDF9F0")
    static let primary = Color(hex: "2E2418")
    static let accent = Color(hex: "D4B483")
    static let surface = Color(hex: "F5EDD5")
    static let border = Color(hex: "EAE0C8")
    static let textPrimary = Color(hex: "1C1917")
    static let textSecondary = Color(hex: "7A6A4A")
    static let textMuted = Color(hex: "A8926A")

    // MARK: - Typography
    static func heading(_ size: CGFloat) -> Font {
        .system(size: size, weight: .medium, design: .default)
    }

    static func body(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .regular, design: .default)
    }

    static func serif(_ size: CGFloat = 16) -> Font {
        .custom("Georgia", size: size)
    }

    static func serifMedium(_ size: CGFloat = 16) -> Font {
        .custom("Georgia-Bold", size: size)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
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
