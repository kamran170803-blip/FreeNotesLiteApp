import SwiftUI
import PencilKit

struct DrawingView: UIViewRepresentable {

    @Binding var drawing: Data?

    var tool: AnnotationTool
    var color: UIColor
    var width: CGFloat

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()

        if let data = drawing,
           let drawing = try? PKDrawing(data: data) {
            canvas.drawing = drawing
        }
        canvas.delegate = context.coordinator
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.drawingPolicy = .anyInput

        canvas.minimumZoomScale = 1
        canvas.maximumZoomScale = 4
        canvas.bouncesZoom = true

        applyTool(to: canvas)

        return canvas
    }

    func updateUIView(_ canvas: PKCanvasView, context: Context) {
        if let data = drawing,
           let newDrawing = try? PKDrawing(data: data),
           canvas.drawing != newDrawing {
            canvas.drawing = newDrawing
        }
        applyTool(to: canvas)
    }

    // 🔧 TOOL LOGIC (FIXED)
    func applyTool(to canvas: PKCanvasView) {
        switch tool {
        case .pen:
            canvas.tool = PKInkingTool(.pen, color: color, width: width)

        case .marker:
            canvas.tool = PKInkingTool(
                .marker,
                color: color.withAlphaComponent(0.4),
                width: width * 1.8
            )

        case .eraser:
            canvas.tool = PKEraserTool(.vector)

        case .lasso:
            canvas.tool = PKLassoTool()
        }
    }

    // 🔄 COORDINATOR (sync drawing)
    class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: DrawingView

        init(_ parent: DrawingView) {
            self.parent = parent
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            parent.drawing = canvasView.drawing.dataRepresentation()
        }
    }
}
