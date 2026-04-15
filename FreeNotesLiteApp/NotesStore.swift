import Foundation
import Combine

@MainActor
final class NotesStore: ObservableObject {

    @Published var folders: [NoteFolder] = [] {
        didSet {
            DataManager.shared.saveFolders(folders)
        }
    }

    init() {
        self.folders = DataManager.shared.loadFolders()
        if folders.isEmpty {
            let defaultFolder = NoteFolder(name: "My Notebooks")
            folders.append(defaultFolder)
        }
    }

    func folder(id: UUID) -> NoteFolder? {
        folders.first { $0.id == id }
    }

    func notebook(folderID: UUID, notebookID: UUID) -> Notebook? {
        folder(id: folderID)?.notebooks.first { $0.id == notebookID }
    }

    func page(folderID: UUID, notebookID: UUID, pageID: UUID) -> NotePage? {
        notebook(folderID: folderID, notebookID: notebookID)?.pages.first { $0.id == pageID }
    }

    func addFolder(name: String = "New Folder") {
        folders.append(NoteFolder(name: name))
    }

    func addNotebook(folderID: UUID, title: String = "New Notebook") {
        guard let folderIndex = folders.firstIndex(where: { $0.id == folderID }) else { return }
        folders[folderIndex].notebooks.append(Notebook(title: title))
    }

    func addNotebook(folderID: UUID, title: String, cover: NotebookCover, template: PageStyle) {
        guard let folderIndex = folders.firstIndex(where: { $0.id == folderID }) else { return }
        var notebook = Notebook(title: title)
        notebook.cover = cover
        notebook.template = template
        let defaultPage = NotePage(style: template, pageColorHex: "FFFDF7", pdfFileName: nil, drawingData: nil)
        notebook.pages.append(defaultPage)
        folders[folderIndex].notebooks.append(notebook)
    }

    func addPage(folderID: UUID, notebookID: UUID, style: PageStyle = .blank, pageColorHex: String = "FFFDF7", pdfFileName: String? = nil) {
        guard let folderIndex = folders.firstIndex(where: { $0.id == folderID }),
              let notebookIndex = folders[folderIndex].notebooks.firstIndex(where: { $0.id == notebookID }) else { return }

        let page = NotePage(
            style: style,
            pageColorHex: pageColorHex,
            pdfFileName: pdfFileName,
            drawingData: nil
        )
        folders[folderIndex].notebooks[notebookIndex].pages.append(page)
    }

    func addPage(folderID: UUID, notebookID: UUID) {
        addPage(folderID: folderID, notebookID: notebookID, style: .blank)
    }

    func duplicatePage(folderID: UUID, notebookID: UUID, pageID: UUID) {
        guard let folderIndex = folders.firstIndex(where: { $0.id == folderID }),
              let notebookIndex = folders[folderIndex].notebooks.firstIndex(where: { $0.id == notebookID }),
              let originalPage = folders[folderIndex].notebooks[notebookIndex].pages.first(where: { $0.id == pageID }) else { return }

        var newPage = originalPage
        newPage.id = UUID()
        newPage.versionHistory = []   // fresh history for duplicate
        folders[folderIndex].notebooks[notebookIndex].pages.append(newPage)
    }

    func deletePage(folderID: UUID, notebookID: UUID, pageID: UUID) {
        guard let folderIndex = folders.firstIndex(where: { $0.id == folderID }),
              let notebookIndex = folders[folderIndex].notebooks.firstIndex(where: { $0.id == notebookID }),
              let pageIndex = folders[folderIndex].notebooks[notebookIndex].pages.firstIndex(where: { $0.id == pageID }) else { return }
        folders[folderIndex].notebooks[notebookIndex].pages.remove(at: pageIndex)
    }

    func rotatePDFPage(folderID: UUID, notebookID: UUID, pageID: UUID, rotation: Int) {
        // For PDF rotation, you'd modify the PDF document; here we store a rotation flag if needed.
        // For simplicity, we'll rely on PDFKit rotation later.
        // Placeholder.
    }

    func updatePage(folderID: UUID, notebookID: UUID, pageID: UUID, mutate: (inout NotePage) -> Void) {
        guard let folderIndex = folders.firstIndex(where: { $0.id == folderID }),
              let notebookIndex = folders[folderIndex].notebooks.firstIndex(where: { $0.id == notebookID }),
              let pageIndex = folders[folderIndex].notebooks[notebookIndex].pages.firstIndex(where: { $0.id == pageID }) else { return }

        mutate(&folders[folderIndex].notebooks[notebookIndex].pages[pageIndex])
    }

    func setPageStyle(folderID: UUID, notebookID: UUID, pageID: UUID, style: PageStyle) {
        updatePage(folderID: folderID, notebookID: notebookID, pageID: pageID) { $0.style = style }
    }

    func setPageColor(folderID: UUID, notebookID: UUID, pageID: UUID, hex: String) {
        updatePage(folderID: folderID, notebookID: notebookID, pageID: pageID) { $0.pageColorHex = hex }
    }

    func setPageDrawing(folderID: UUID, notebookID: UUID, pageID: UUID, data: Data?) {
        updatePage(folderID: folderID, notebookID: notebookID, pageID: pageID) { $0.drawingData = data }
    }

    func setPDFDrawing(folderID: UUID, notebookID: UUID, pageID: UUID, pageIndex: Int, data: Data?) {
        updatePage(folderID: folderID, notebookID: notebookID, pageID: pageID) {
            $0.drawingPerPDFPage[pageIndex] = data
        }
    }

    // MARK: - Version History

    func saveVersion(folderID: UUID, notebookID: UUID, pageID: UUID) {
        guard let page = page(folderID: folderID, notebookID: notebookID, pageID: pageID) else { return }
        let version = PageVersion(
            timestamp: Date(),
            drawingData: page.drawingData,
            drawingPerPDFPage: page.drawingPerPDFPage,
            thumbnailData: nil // can generate later
        )
        updatePage(folderID: folderID, notebookID: notebookID, pageID: pageID) {
            $0.versionHistory.append(version)
        }
    }

    func restoreVersion(folderID: UUID, notebookID: UUID, pageID: UUID, versionID: UUID) {
        guard let page = page(folderID: folderID, notebookID: notebookID, pageID: pageID),
              let version = page.versionHistory.first(where: { $0.id == versionID }) else { return }
        updatePage(folderID: folderID, notebookID: notebookID, pageID: pageID) {
            $0.drawingData = version.drawingData
            $0.drawingPerPDFPage = version.drawingPerPDFPage
        }
    }

    // MARK: - Audio

    func setPageAudioURL(folderID: UUID, notebookID: UUID, pageID: UUID, url: URL?) {
        updatePage(folderID: folderID, notebookID: notebookID, pageID: pageID) { $0.audioURL = url }
    }
}
