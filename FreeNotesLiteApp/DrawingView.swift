import SwiftUI
import PencilKit

struct DrawingView: UIViewRepresentable {
    @Binding var drawingData: Data?
    var tool: AnnotationTool
    var colorHex: String
    var lineWidth: CGFloat

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.drawingPolicy = .anyInput
        canvas.isScrollEnabled = false
        canvas.delegate = context.coordinator
        applyTool(to: canvas)
        syncDrawing(on: canvas)
        return canvas
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        applyTool(to: uiView)
        syncDrawing(on: uiView)
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
        }
    }

    private func syncDrawing(on canvas: PKCanvasView) {
        if let drawingData,
           let drawing = try? PKDrawing(data: drawingData) {
            if canvas.drawing.dataRepresentation() != drawingData {
                canvas.drawing = drawing
            }
        } else if drawingData == nil, !canvas.drawing.strokes.isEmpty {
            canvas.drawing = PKDrawing()
        }
    }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: DrawingView

        init(_ parent: DrawingView) {
            self.parent = parent
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            let data = canvasView.drawing.dataRepresentation()
            Task { @MainActor in
                self.parent.drawingData = data
            }
        }
    }
}
