import SwiftUI
import PencilKit

struct DrawingView: UIViewRepresentable {
    @Binding var drawingData: Data?
    var toolPicker: PKToolPicker?
    var onCanvasCreated: (PKCanvasView) -> Void

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.drawingPolicy = .anyInput
        canvas.isScrollEnabled = false
        canvas.delegate = context.coordinator
        syncDrawing(on: canvas)
        onCanvasCreated(canvas)
        return canvas
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        syncDrawing(on: uiView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    private func syncDrawing(on canvas: PKCanvasView) {
        if let drawingData,
           let drawing = try? PKDrawing(data: drawingData) {
            if canvas.drawing != drawing {
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
            let newData = canvasView.drawing.dataRepresentation()
            Task { @MainActor in
                self.parent.drawingData = newData
            }
        }
    }
}
