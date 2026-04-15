import SwiftUI
import Foundation

enum PageStyle: String, Codable, CaseIterable, Identifiable {
    case blank
    case ruled
    case doubleRuled
    case grid

    var id: String { rawValue }

    var title: String {
        switch self {
        case .blank: return "Blank"
        case .ruled: return "Ruled"
        case .doubleRuled: return "Double Ruled"
        case .grid: return "Grid"
        }
    }
}

struct NoteFolder: Identifiable, Codable {
    var id = UUID()
    var name: String
    var notebooks: [Notebook] = []
}

struct Notebook: Identifiable, Codable {
    var id = UUID()
    var title: String
    var pages: [NotePage] = []
}

struct NotePage: Identifiable, Codable {
    let id: UUID = UUID()
    var style: PageStyle
    var pageColorHex: String
    var pdfFileName: String?

    // NEW SYSTEM
    var drawingData: Data? = nil
    var drawingPerPDFPage: [Int: Data] = [:]
}

extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var rgb: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&rgb)

        let r, g, b: Double
        switch cleaned.count {
        case 6:
            r = Double((rgb >> 16) & 0xFF) / 255.0
            g = Double((rgb >> 8) & 0xFF) / 255.0
            b = Double(rgb & 0xFF) / 255.0
        default:
            r = 1
            g = 1
            b = 1
        }

        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }
}
