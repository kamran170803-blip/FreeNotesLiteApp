import SwiftUI
import PDFKit
import PencilKit

struct PDFPageEditorView: UIViewRepresentable {
    let url: URL
    var pageIndex: Int
    @Binding var drawingPerPage: [Int: Data]
    var tool: AnnotationTool
    var colorHex: String
    var lineWidth: CGFloat

    func makeUIView(context: Context) -> PDFAnnotationContainerView {
        let container = PDFAnnotationContainerView()
        container.pdfView.document = PDFDocument(url: url)
        container.canvasView.delegate = context.coordinator
        applyTool(to: container.canvasView)
        syncDrawing(on: container.canvasView)
        return container
    }

    func updateUIView(_ uiView: PDFAnnotationContainerView, context: Context) {
        if uiView.pdfView.document?.documentURL != url {
            uiView.pdfView.document = PDFDocument(url: url)
        }
        applyTool(to: uiView.canvasView)
        syncDrawing(on: uiView.canvasView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    private func applyTool(to canvas: PKCanvasView) {
        switch tool {
        case .pen:
            canvas.tool = PKInkingTool(.pen, color: UIColor(hex: colorHex), width: lineWidth)
        case .marker:
            canvas.tool = PKInkingTool(.marker, color: UIColor(hex: colorHex), width: lineWidth * 1.8)
        case .eraser:
            canvas.tool = PKEraserTool(.bitmap)
        case .lasso:
            canvas.tool = PKLassoTool()
        }
    }

    private func syncDrawing(on canvas: PKCanvasView) {
        if let data = drawingPerPage[pageIndex],
           let drawing = try? PKDrawing(data: data) {
            if canvas.drawing.dataRepresentation() != data {
                canvas.drawing = drawing
            }
        } else if drawingPerPage[pageIndex] == nil, !canvas.drawing.strokes.isEmpty {
            canvas.drawing = PKDrawing()
        }
    }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: PDFPageEditorView

        init(_ parent: PDFPageEditorView) {
            self.parent = parent
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            let newData = canvasView.drawing.dataRepresentation()
            Task { @MainActor in
                self.parent.drawingPerPage[self.parent.pageIndex] = newData
            }
        }
    }
}

// PDFAnnotationContainerView remains unchanged
final class PDFAnnotationContainerView: UIView {
    let pdfView = PDFView()
    let canvasView = PKCanvasView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        backgroundColor = .clear

        pdfView.translatesAutoresizingMaskIntoConstraints = false
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = .secondarySystemBackground

        canvasView.translatesAutoresizingMaskIntoConstraints = false
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        canvasView.drawingPolicy = .anyInput
        canvasView.isScrollEnabled = false

        addSubview(pdfView)
        addSubview(canvasView)

        NSLayoutConstraint.activate([
            pdfView.leadingAnchor.constraint(equalTo: leadingAnchor),
            pdfView.trailingAnchor.constraint(equalTo: trailingAnchor),
            pdfView.topAnchor.constraint(equalTo: topAnchor),
            pdfView.bottomAnchor.constraint(equalTo: bottomAnchor),

            canvasView.leadingAnchor.constraint(equalTo: leadingAnchor),
            canvasView.trailingAnchor.constraint(equalTo: trailingAnchor),
            canvasView.topAnchor.constraint(equalTo: topAnchor),
            canvasView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}
