import SwiftUI

struct PageLines: View {
    let style: PageStyle

    var body: some View {
        Canvas { context, size in
            let lineColor = Color.black.opacity(0.10)
            let gridColor = Color.black.opacity(0.08)

            switch style {
            case .blank:
                break
            case .ruled:
                let spacing: CGFloat = 30
                for y in stride(from: spacing, through: size.height, by: spacing) {
                    var path = Path()
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                    context.stroke(path, with: .color(lineColor), lineWidth: 1)
                }
            case .doubleRuled:
                let groupSpacing: CGFloat = 34
                let pairGap: CGFloat = 8
                for y in stride(from: groupSpacing, through: size.height, by: groupSpacing) {
                    var path1 = Path()
                    path1.move(to: CGPoint(x: 0, y: y))
                    path1.addLine(to: CGPoint(x: size.width, y: y))
                    context.stroke(path1, with: .color(lineColor), lineWidth: 1)

                    var path2 = Path()
                    path2.move(to: CGPoint(x: 0, y: y + pairGap))
                    path2.addLine(to: CGPoint(x: size.width, y: y + pairGap))
                    context.stroke(path2, with: .color(lineColor.opacity(0.75)), lineWidth: 1)
                }
            case .grid:
                let spacing: CGFloat = 28
                for x in stride(from: spacing, through: size.width, by: spacing) {
                    var path = Path()
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                    context.stroke(path, with: .color(gridColor), lineWidth: 1)
                }
                for y in stride(from: spacing, through: size.height, by: spacing) {
                    var path = Path()
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                    context.stroke(path, with: .color(gridColor), lineWidth: 1)
                }
            }
        }
    }
}
