import SwiftUI
import Foundation

enum PageStyle: String, Codable, CaseIterable, Identifiable {
    case blank, ruled, doubleRuled, grid
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

enum NotebookCover: String, Codable, CaseIterable, Identifiable {
    case none, leather, fabric, geometric, abstract
    var id: String { rawValue }
    var imageName: String {
        switch self {
        case .none: return "book.closed.fill"
        case .leather: return "book.fill"
        case .fabric: return "book.circle.fill"
        case .geometric: return "triangle.fill"
        case .abstract: return "circle.hexagongrid.fill"
        }
    }
    var displayName: String {
        switch self {
        case .none: return "No Cover"
        case .leather: return "Leather"
        case .fabric: return "Fabric"
        case .geometric: return "Geometric"
        case .abstract: return "Abstract"
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
    var cover: NotebookCover = .none
    var template: PageStyle = .blank
    var pages: [NotePage] = []
}

struct NotePage: Identifiable, Codable {
    var id = UUID()
    var style: PageStyle
    var pageColorHex: String
    var pdfFileName: String?
    var drawing: Data? = nil
    var drawingPerPDFPage: [Int: Data] = [:]
    var audioURL: URL?                     // local file URL for audio recording
    var versionHistory: [PageVersion] = []  // saved snapshots
}

struct PageVersion: Identifiable, Codable {
    var id = UUID()
    var timestamp: Date
    var drawing: Data?
    var drawingPerPDFPage: [Int: Data]
    var thumbnailData: Data?   // optional preview
}


extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var rgb: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }
}

