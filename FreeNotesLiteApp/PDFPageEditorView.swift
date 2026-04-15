import SwiftUI
import PDFKit
import PencilKit

struct PDFPageEditorView: UIViewRepresentable {
    let url: URL
    @Binding var currentPageIndex: Int
    @Binding var drawingPerPage: [Int: Data]
    var toolPicker: PKToolPicker?
    var onCanvasCreated: (PKCanvasView) -> Void

    func makeUIView(context: Context) -> PDFAnnotationContainerView {
        let container = PDFAnnotationContainerView()

        container.pdfView.document = PDFDocument(url: url)
        container.pdfView.autoScales = true
        container.pdfView.displayMode = .singlePage
        container.pdfView.displayDirection = .horizontal
        container.pdfView.usePageViewController(true, withViewOptions: nil)
        container.pdfView.pageBreakMargins = .zero
        container.pdfView.backgroundColor = .secondarySystemBackground
        container.pdfView.displaysPageBreaks = false

        container.canvasView.delegate = context.coordinator
        syncDrawing(on: container.canvasView)
        onCanvasCreated(container.canvasView)

        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.pageDidChange(_:)),
            name: .PDFViewPageChanged,
            object: container.pdfView
        )

        return container
    }

    func updateUIView(_ uiView: PDFAnnotationContainerView, context: Context) {
        if uiView.pdfView.document?.documentURL != url {
            uiView.pdfView.document = PDFDocument(url: url)
        }

        if let page = uiView.pdfView.document?.page(at: currentPageIndex) {
            uiView.pdfView.go(to: page)
        }

        syncDrawing(on: uiView.canvasView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    private func syncDrawing(on canvas: PKCanvasView) {
        if let data = drawingPerPage[currentPageIndex],
           let drawing = try? PKDrawing(data: data) {
            if canvas.drawing != drawing {
                canvas.drawing = drawing
            }
        } else if drawingPerPage[currentPageIndex] == nil, !canvas.drawing.strokes.isEmpty {
            canvas.drawing = PKDrawing()
        }
    }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: PDFPageEditorView

        init(_ parent: PDFPageEditorView) {
            self.parent = parent
        }

        deinit {
            NotificationCenter.default.removeObserver(self)
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            let newData = canvasView.drawing.dataRepresentation()
            Task { @MainActor in
                self.parent.drawingPerPage[self.parent.currentPageIndex] = newData
            }
        }

        @objc func pageDidChange(_ notification: Notification) {
            guard let pdfView = notification.object as? PDFView,
                  let currentPage = pdfView.currentPage,
                  let document = pdfView.document else { return }

            let pageIndex = document.index(for: currentPage)
            guard pageIndex >= 0, pageIndex < document.pageCount else { return }

            Task { @MainActor in
                self.parent.currentPageIndex = pageIndex
            }
        }
    }
}

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
