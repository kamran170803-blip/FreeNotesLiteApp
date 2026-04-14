import SwiftUI
import PencilKit

struct DrawingView: View {
    @Binding var drawingData: Data

    private let canvasView = PKCanvasView()

    var body: some View {
        VStack {
            CanvasRepresentable(canvasView: canvasView, drawingData: $drawingData)
                .edgesIgnoringSafeArea(.all)
        }
        .onAppear {
            if let drawing = try? PKDrawing(data: drawingData) {
                canvasView.drawing = drawing
            }

            canvasView.tool = PKInkingTool(.pen, color: .black, width: 5)
            canvasView.drawingPolicy = .anyInput
        }
    }
}
struct CanvasRepresentable: UIViewRepresentable {
    let canvasView: PKCanvasView
    @Binding var drawingData: Data

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {}

    static func dismantleUIView(_ uiView: PKCanvasView, coordinator: ()) {}
}
