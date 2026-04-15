import SwiftUI
import PencilKit
import UIKit

enum AnnotationTool: String, CaseIterable, Identifiable {
    case pen
    case marker
    case eraser
    case lasso

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pen: return "Pen"
        case .marker: return "Marker"
        case .eraser: return "Eraser"
        case .lasso: return "Lasso"
        }
    }

    var systemImage: String {
        switch self {
        case .pen: return "pencil.tip"
        case .marker: return "highlighter"
        case .eraser: return "eraser"
        case .lasso: return "lasso"
        }
    }
}

extension UIColor {
    convenience init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var rgb: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&rgb)

        let r, g, b: CGFloat
        switch cleaned.count {
        case 6:
            r = CGFloat((rgb >> 16) & 0xFF) / 255.0
            g = CGFloat((rgb >> 8) & 0xFF) / 255.0
            b = CGFloat(rgb & 0xFF) / 255.0
        default:
            r = 0.07
            g = 0.07
            b = 0.07
        }

        self.init(red: r, green: g, blue: b, alpha: 1)
    }
}
