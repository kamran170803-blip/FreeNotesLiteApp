import SwiftUI
import PencilKit
import PDFKit   // <-- ADD THIS

struct PageContentView: View {
    @State private var selectedTool: AnnotationTool = .pen
    @State private var selectedColor: UIColor = .black
    @State private var strokeWidth: CGFloat = 5
    
    @State private var paletteColors: [UIColor] = [
        .black, .systemBlue, .systemRed, .systemGreen,
        .systemOrange, .systemPurple, .systemTeal,
        .systemPink, .brown, .darkGray, .cyan, .magenta
    ]

    @State private var showingCustomColorPicker = false
    

    
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
                pdfContent(pdfName: pdfName)
            } else {
                noteContent
            }
        }
        .sheet(isPresented: $showingCustomColorPicker) {
            UIColorPickerSheet(
                selectedColor: $selectedColor,
                onSave: { newColor in
                    paletteColors.append(newColor)
                    selectedColor = newColor
                },
                dismiss: {
                    showingCustomColorPicker = false
                }
            )
        }
    }

    @ViewBuilder
    private func pdfContent(pdfName: String) -> some View {
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
    }

    private var noteContent: some View {
        ZStack {
            RoundedRectangle ( cornerRadius: 18, style: .continuous)
                .fill(Color.white)
        }
        .shadow(radius: 8)
        .padding(8)
    }

   

    

    private var noteDrawingLayer: AnyView {
        if isLastNotebookPage {
            return AnyView(
                DrawingView(
                    drawing: drawingBinding(pageID: page.id),
                    tool: selectedTool,
                    color: selectedColor,
                    width: strokeWidth,
                    onNearBottom: { appendNextBlankPage() }
                )
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .padding(10)
            )
        }

        return AnyView(
            DrawingView(
                drawing: drawingBinding(pageID: page.id),
                tool: selectedTool,
                color: selectedColor,
                width: strokeWidth
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .padding(10)
        )
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
                store.page(folderID: folderID, notebookID: notebookID, pageID: pageID)?.drawing
            },
            set: { newValue in
                store.updatePage(folderID: folderID, notebookID: notebookID, pageID: pageID) {
                    $0.drawing = newValue
                }
            }
        )
    }
    private var isLastNotebookPage: Bool {
        guard let notebook = store.notebook(folderID: folderID, notebookID: notebookID) else { return false }
        return notebook.pages.last?.id == page.id && page.pdfFileName == nil
    }

    private func appendNextBlankPage() {
        guard page.pdfFileName == nil else { return }
        store.addPage(
            folderID: folderID,
            notebookID: notebookID,
            style: page.style,
            pageColorHex: page.pageColorHex
        )
    }

   
        }
   

    
    private func isSameColor(_ lhs: UIColor, _ rhs: UIColor) -> Bool {
        var lr: CGFloat = 0, lg: CGFloat = 0, lb: CGFloat = 0, la: CGFloat = 0
        var rr: CGFloat = 0, rg: CGFloat = 0, rb: CGFloat = 0, ra: CGFloat = 0

        lhs.getRed(&lr, green: &lg, blue: &lb, alpha: &la)
        rhs.getRed(&rr, green: &rg, blue: &rb, alpha: &ra)

        return abs(lr - rr) < 0.01 &&
               abs(lg - rg) < 0.01 &&
               abs(lb - rb) < 0.01 &&
               abs(la - ra) < 0.01
    }

