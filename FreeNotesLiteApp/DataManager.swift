import Foundation
import PDFKit
import PencilKit
import UIKit

final class DataManager {
    static let shared = DataManager()
    private init() {}

    private var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private var dataURL: URL {
        documentsURL.appendingPathComponent("freenotes_data.json")
    }

    private var pdfFolderURL: URL {
        documentsURL.appendingPathComponent("ImportedPDFs", isDirectory: true)
    }

    func loadFolders() -> [NoteFolder] {
        do {
            guard FileManager.default.fileExists(atPath: dataURL.path) else { return [] }
            let data = try Data(contentsOf: dataURL)
            return try JSONDecoder().decode([NoteFolder].self, from: data)
        } catch {
            print("Load error:", error)
            return []
        }
    }

    func saveFolders(_ folders: [NoteFolder]) {
        do {
            let data = try JSONEncoder().encode(folders)
            try data.write(to: dataURL, options: [.atomic])
        } catch {
            print("Save error:", error)
        }
    }

    func ensurePDFFolderExists() {
        if !FileManager.default.fileExists(atPath: pdfFolderURL.path) {
            try? FileManager.default.createDirectory(at: pdfFolderURL, withIntermediateDirectories: true)
        }
    }

    func importPDF(from sourceURL: URL) -> String? {
        ensurePDFFolderExists()

        let fileName = UUID().uuidString + ".pdf"
        let destinationURL = pdfFolderURL.appendingPathComponent(fileName)

        let didAccess = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if didAccess {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }

        do {
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
            return fileName
        } catch {
            print("PDF import error:", error)
            return nil
        }
    }

    func pdfURL(for fileName: String) -> URL {
        pdfFolderURL.appendingPathComponent(fileName)
    }

    // FIXED: Accepts dictionary of per‑page drawings
    func exportAnnotatedPDF(originalURL: URL, drawingsPerPage: [Int: Data]) -> URL? {
        guard let document = PDFDocument(url: originalURL) else { return nil }

        let outputURL = FileManager.default
            .temporaryDirectory
            .appendingPathComponent(UUID().uuidString + "_annotated.pdf")

        let newDocument = PDFDocument()

        for i in 0..<document.pageCount {
            guard let page = document.page(at: i) else { continue }

            let bounds = page.bounds(for: .mediaBox)
            let renderer = UIGraphicsPDFRenderer(bounds: bounds)

            let data = renderer.pdfData { context in
                context.beginPage()
                page.draw(with: .mediaBox, to: context.cgContext)

                if let drawingData = drawingsPerPage[i],
                   let drawing = try? PKDrawing(data: drawingData) {
                    let image = drawing.image(from: bounds, scale: 1.0)
                    if let cgImage = image.cgImage {
                        context.cgContext.draw(cgImage, in: bounds)
                    }
                }
            }

            if let newDoc = PDFDocument(data: data),
               let newPage = newDoc.page(at: 0) {
                newDocument.insert(newPage, at: i)
            }
        }

        newDocument.write(to: outputURL)
        return outputURL
    }
}
