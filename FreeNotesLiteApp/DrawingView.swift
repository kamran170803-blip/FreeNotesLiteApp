import SwiftUI
import PencilKit

struct DrawingView: UIViewRepresentable {
    @Binding var drawing: Data?

    var tool: AnnotationTool
    var color: UIColor
    var width: CGFloat
    var onNearBottom: (() -> Void)? = nil
    var onCanvasCreated: ((PKCanvasView) -> Void)? = nil

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.delegate = context.coordinator
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.drawingPolicy = .anyInput
        canvas.minimumZoomScale = 1
        canvas.maximumZoomScale = 4
        canvas.bouncesZoom = true

        if let data = drawing, let pkDrawing = try? PKDrawing(data: data) {
            canvas.drawing = pkDrawing
        }

        applyTool(to: canvas)
        onCanvasCreated?(canvas)
        return canvas
    }

    func updateUIView(_ canvas: PKCanvasView, context: Context) {
        if let data = drawing,
           let pkDrawing = try? PKDrawing(data: data),
           canvas.drawing != pkDrawing {
            canvas.drawing = pkDrawing
        }

        applyTool(to: canvas)
    }

    private func applyTool(to canvas: PKCanvasView) {
        switch tool {
        case .pen:
            canvas.tool = PKInkingTool(.pen, color: color, width: width)
        case .marker:
            canvas.tool = PKInkingTool(.marker, color: color.withAlphaComponent(0.4), width: width * 1.8)
        case .eraser:
            canvas.tool = PKEraserTool(.vector)
        case .lasso:
            canvas.tool = PKLassoTool()
        }
    }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: DrawingView
        private var didTriggerNearBottom = false

        init(_ parent: DrawingView) {
            self.parent = parent
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            parent.drawing = canvasView.drawing.dataRepresentation()

            guard let onNearBottom = parent.onNearBottom else { return }
            let bounds = canvasView.drawing.bounds
            let nearBottom = bounds.maxY > (canvasView.bounds.height - 140)

            if nearBottom && !didTriggerNearBottom {
                didTriggerNearBottom = true
                onNearBottom()
            } else if !nearBottom {
                didTriggerNearBottom = false
            }
        }
    }
}
