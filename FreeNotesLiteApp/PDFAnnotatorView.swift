import SwiftUI
import PDFKit
import PencilKit

struct PDFAnnotatorView: UIViewRepresentable {
    
    let url: URL
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        
        let document = PDFDocument(url: url)
        pdfView.document = document
        
        // Add drawing overlay
        let canvas = PKCanvasView()
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.drawingPolicy = .anyInput
        
        canvas.tool = PKInkingTool(.pen, color: .red, width: 3)
        
        pdfView.addSubview(canvas)
        
        canvas.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            canvas.leadingAnchor.constraint(equalTo: pdfView.leadingAnchor),
            canvas.trailingAnchor.constraint(equalTo: pdfView.trailingAnchor),
            canvas.topAnchor.constraint(equalTo: pdfView.topAnchor),
            canvas.bottomAnchor.constraint(equalTo: pdfView.bottomAnchor)
        ])
        
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {}
}
