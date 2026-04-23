import SwiftUI

// MARK: - Brand palette
// Restores the former MyLifeNative light workspace language: cool sidebar,
// blue selection, soft cards, and high-contrast operational text.

enum AppPalette {
    static let ink = Color(hex: "24252B")
    static let graphite = Color(hex: "3F4149")
    static let steel = Color(hex: "7A7D84")
    static let mist = Color(hex: "D9DEE7")
    static let paper = Color(hex: "FAFBFD")
    static let porcelain = Color(hex: "F4F7FA")
    static let sidebar = Color(hex: "EEF8FC")
    static let sidebarStroke = Color(hex: "E5EEF5")
    static let snow = Color.white

    static let blue = Color(hex: "2F6EEA")
    static let softBlue = Color(hex: "E8F0FF")
    static let green = Color(hex: "5DBB63")
    static let orange = Color(hex: "F08A3E")
    static let red = Color(hex: "E35D57")
    static let gold = Color(hex: "C6923A")
}

// MARK: - Semantic tokens
// Mapped over the legacy AppTheme surface so existing views migrate for free.
// Switch `scheme` to drive the dark executive variant.

enum AppTheme {
    // Surfaces
    static let background = AppPalette.paper
    static let surface = AppPalette.snow
    static let elevated = AppPalette.porcelain
    static let sidebar = AppPalette.sidebar
    static let sidebarStroke = AppPalette.sidebarStroke
    static let stroke = AppPalette.mist.opacity(0.78)

    // Text
    static let text = AppPalette.ink
    static let secondaryText = AppPalette.steel
    static let mutedText = AppPalette.steel.opacity(0.72)

    // Accents
    static let accent = AppPalette.blue
    static let success = AppPalette.green
    static let warning = AppPalette.orange
    static let danger = AppPalette.red
    static let gold = AppPalette.gold

    // Geometry
    static let cornerRadius: CGFloat = 22
    static let cornerRadiusSmall: CGFloat = 12
    static let cornerRadiusPill: CGFloat = 999

    // Elevation presets
    static let shadowContact = Color.black.opacity(0.035)
    static let shadowLift = Color.black.opacity(0.075)
}

// MARK: - Typography
// Ordered fallbacks per role: the first registered family wins, system font last.

enum AppTypography {
    private static let displayCandidates = ["Inter", "Inter Variable"]
    private static let bodyCandidates = ["Inter", "Inter Variable"]
    private static let brandCandidates = ["Caesar Display", "EB Garamond"]

    static func display(size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        if let family = firstRegistered(displayCandidates) {
            return customFont(family: family, weight: weight, size: size)
        }
        return .system(size: size, weight: weight, design: .rounded)
    }

    static func body(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        if let family = firstRegistered(bodyCandidates) {
            return customFont(family: family, weight: weight, size: size)
        }
        return .system(size: size, weight: weight, design: .default)
    }

    /// Build a Font from a registered family + weight. Prefers a matching
    /// PostScript face (e.g. `InterVariable-SemiBold`) when available and
    /// falls back to `.custom(family:).weight(weight)` otherwise.
    private static func customFont(family: String, weight: Font.Weight, size: CGFloat) -> Font {
        if let postScript = postScriptName(for: family, weight: weight) {
            return .custom(postScript, size: size)
        }
        return .custom(family, size: size).weight(weight)
    }

    private static func postScriptName(for family: String, weight: Font.Weight) -> String? {
        let suffix = suffix(for: weight)
        switch family {
        case "Inter Variable":
            return suffix.isEmpty ? "InterVariable" : "InterVariable-\(suffix)"
        default:
            return nil
        }
    }

    private static func suffix(for weight: Font.Weight) -> String {
        switch weight {
        case .ultraLight: return "Thin"
        case .thin: return "Thin"
        case .light: return "Light"
        case .regular: return ""
        case .medium: return "Medium"
        case .semibold: return "SemiBold"
        case .bold: return "Bold"
        case .heavy, .black: return "ExtraBold"
        default: return ""
        }
    }

    static var heroTitle: Font { display(size: 36, weight: .bold) }
    static var brandTitle: Font {
        if let family = firstRegistered(brandCandidates) {
            return .custom(family, size: 62).weight(.medium)
        }
        return .system(size: 62, weight: .medium, design: .serif)
    }
    static var brandSubtitle: Font { body(size: 16, weight: .regular) }
    static var pageTitle: Font { display(size: 30, weight: .bold) }
    static var sectionTitle: Font { display(size: 22, weight: .bold) }
    static var metricValue: Font { display(size: 30, weight: .bold) }

    static var bodyRegular: Font { body(size: 14, weight: .regular) }
    static var bodyMedium: Font { body(size: 14, weight: .medium) }
    static var caption: Font { body(size: 12, weight: .regular) }
    static var eyebrow: Font { body(size: 11, weight: .semibold) }

    private static func firstRegistered(_ candidates: [String]) -> String? {
        #if canImport(AppKit)
        let available = Set(NSFontManager.shared.availableFontFamilies)
        #elseif canImport(UIKit)
        let available = Set(UIFont.familyNames)
        #else
        let available: Set<String> = []
        #endif
        return candidates.first(where: { available.contains($0) })
    }
}

#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

// MARK: - Motion
// Centralized animation curves so route / selection / hover transitions read
// as one coherent motion language across the app.

enum AppMotion {
    /// Primary transition for route changes and panel swaps — firm but soft.
    static let route: Animation = .spring(response: 0.45, dampingFraction: 0.82)

    /// Snappier curve for local affordances (hover, selection indicator, pills).
    static let selection: Animation = .spring(response: 0.32, dampingFraction: 0.78)

    /// Ease used for opacity crossfades on content changes.
    static let crossfade: Animation = .easeInOut(duration: 0.22)
}

// MARK: - Brand strings
enum AppBrand {
    static let name = "Caesar"
    static let tagline = "Seu workspace pessoal de finanças, direito e webdevelopment."
    static let pillars = ["Pessoal", "Jurídico", "Finanças", "Developer"]
}

// MARK: - Color(hex:)
extension Color {
    init(hex: String) {
        let sanitized = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: sanitized).scanHexInt64(&value)
        let r: Double
        let g: Double
        let b: Double
        let a: Double
        switch sanitized.count {
        case 8:
            a = Double((value & 0xFF000000) >> 24) / 255
            r = Double((value & 0x00FF0000) >> 16) / 255
            g = Double((value & 0x0000FF00) >> 8) / 255
            b = Double(value & 0x000000FF) / 255
        case 6:
            a = 1
            r = Double((value & 0xFF0000) >> 16) / 255
            g = Double((value & 0x00FF00) >> 8) / 255
            b = Double(value & 0x0000FF) / 255
        case 3:
            a = 1
            r = Double((value & 0xF00) >> 8) / 15
            g = Double((value & 0x0F0) >> 4) / 15
            b = Double(value & 0x00F) / 15
        default:
            a = 1
            r = 0.45
            g = 0.45
            b = 0.45
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}
