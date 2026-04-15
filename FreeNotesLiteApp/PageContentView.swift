import SwiftUI
import PencilKit
import PDFKit   // <-- ADD THIS

struct PageContentView: View {
    @State private var selectedTool: AnnotationTool = .pen
    @State private var selectedColor: UIColor = .black
    @State private var strokewidth: CGFloat = 5
    @EnvironmentObject var store: NotesStore
    let folderID: UUID
    let notebookID: UUID
    let page: NotePage
    let toolPicker: PKToolPicker?
    let onCanvasCreated: (PKCanvasView) -> Void
    @Binding var currentPDFPageIndex: Int

    init(
        folderID: UUID,
        notebookID: UUID,
        page: NotePage,
        toolPicker: PKToolPicker? = nil,
        onCanvasCreated: @escaping (PKCanvasView) -> Void = { _ in },
        currentPDFPageIndex: Binding<Int>
    ) {
        self.folderID = folderID
        self.notebookID = notebookID
        self.page = page
        self.toolPicker = toolPicker
        self.onCanvasCreated = onCanvasCreated
        self._currentPDFPageIndex = currentPDFPageIndex
    }

    var body: some View {
        ZStack {
            if let pdfName = page.pdfFileName {
                PDFPageEditorView(
                    url: DataManager.shared.pdfURL(for: pdfName),
                    currentPageIndex: $currentPDFPageIndex,
                    drawingPerPage: pdfDrawingBinding(pageID: page.id),
                    toolPicker: toolPicker,
                    onCanvasCreated: onCanvasCreated
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
                        drawingData: Binding(
                            get: {
                                page.drawingPerPDFPage[currentPDFPageIndex]
                            },
                            set: { newValue in
                                store.updatePage(
                                    folderID: folderID,
                                    notebookID: notebookID,
                                    pageID: page.id
                                ) {
                                    $0.drawingPerPDFPage[currentPDFPageIndex] = newValue
                                }
                            }
                        ),
                        tool: selectedTool,
                        color: selectedColor,
                        width: strokeWidth
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
