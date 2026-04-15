import SwiftUI

struct PageContentView: View {
    @EnvironmentObject var store: NotesStore
    let folderID: UUID
    let notebookID: UUID
    let page: NotePage
    let selectedTool: AnnotationTool
    let selectedColorHex: String
    let lineWidth: CGFloat
    let pdfPageIndex: Int

    init(
        folderID: UUID,
        notebookID: UUID,
        page: NotePage,
        selectedTool: AnnotationTool = .pen,
        selectedColorHex: String = "111111",
        lineWidth: CGFloat = 4,
        pdfPageIndex: Int = 0
    ) {
        self.folderID = folderID
        self.notebookID = notebookID
        self.page = page
        self.selectedTool = selectedTool
        self.selectedColorHex = selectedColorHex
        self.lineWidth = lineWidth
        self.pdfPageIndex = pdfPageIndex
    }

    var body: some View {
        ZStack {
            if let pdfName = page.pdfFileName {
                PDFPageEditorView(
                    url: DataManager.shared.pdfURL(for: pdfName),
                    pageIndex: pdfPageIndex,
                    drawingPerPage: pdfDrawingBinding(pageID: page.id),
                    tool: selectedTool,
                    colorHex: selectedColorHex,
                    lineWidth: lineWidth
                )
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(radius: 8)
                .padding(8)
            } else {
                ZStack {
                    Color(hex: page.pageColorHex)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                    PageLines(style: page.style)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .allowsHitTesting(false)

                    DrawingView(
                        drawingData: drawingBinding(pageID: page.id),
                        tool: selectedTool,
                        colorHex: selectedColorHex,
                        lineWidth: lineWidth
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .padding(10)
                }
                .shadow(radius: 8)
                .padding(8)
            }
        }
    }

    private func pdfDrawingBinding(pageID: UUID) -> Binding<[Int: Data]> {
        Binding(
            get: {
                store.page(folderID: folderID, notebookID: notebookID, pageID: pageID)?.drawingPerPDFPage ?? [:]
            },
            set: { newValue in
                store.updatePage(folderID: folderID, notebookID: notebookID, pageID: pageID) {
                    $0.drawingPerPDFPage = newValue
                }
            }
        )
    }

    private func drawingBinding(pageID: UUID) -> Binding<Data?> {
        Binding(
            get: {
                store.page(folderID: folderID, notebookID: notebookID, pageID: pageID)?.drawingData
            },
            set: { newValue in
                store.updatePage(folderID: folderID, notebookID: notebookID, pageID: pageID) {
                    $0.drawingData = newValue
                }
            }
        )
    }
}

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
