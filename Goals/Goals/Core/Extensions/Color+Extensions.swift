import SwiftUI

extension Color {
    static var goalCardBackground: Color {
        Color(nsColor: .controlBackgroundColor)
    }

    static var goalSecondaryBackground: Color {
        Color(nsColor: .windowBackgroundColor)
    }

    static var goalBorder: Color {
        Color(nsColor: .separatorColor)
    }

    static var goalText: Color {
        Color(nsColor: .labelColor)
    }

    static var goalSecondaryText: Color {
        Color(nsColor: .secondaryLabelColor)
    }

    static var goalTertiaryText: Color {
        Color(nsColor: .tertiaryLabelColor)
    }

    static func forGoalType(_ type: GoalType) -> Color {
        switch type {
        case .bookReading: return .blue
        case .fitness: return .orange
        case .programming: return .purple
        }
    }

    static func forLanguage(_ language: String?) -> Color {
        guard let lang = language?.lowercased() else { return .gray }

        switch lang {
        case "swift": return .orange
        case "python": return .blue
        case "javascript", "typescript": return .yellow
        case "java": return .red
        case "go": return .cyan
        case "rust": return .brown
        case "ruby": return .red
        case "c", "c++", "c#": return .purple
        case "kotlin": return .purple
        case "php": return .indigo
        default: return .gray
        }
    }

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
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
