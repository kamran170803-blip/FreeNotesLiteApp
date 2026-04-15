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

    func addPage(folderID: UUID, notebookID: UUID, style: PageStyle = .blank, pageColorHex: String = "FFFDF7", pdfFileName: String? = nil) {
        guard let folderIndex = folders.firstIndex(where: { $0.id == folderID }),
              let notebookIndex = folders[folderIndex].notebooks.firstIndex(where: { $0.id == notebookID }) else { return }

        let page = NotePage(
            style: style,
            pageColorHex: pageColorHex,
            drawingData: nil,
            pdfFileName: pdfFileName
        )
        folders[folderIndex].notebooks[notebookIndex].pages.append(page)
    }

    func addPage(folderID: UUID, notebookID: UUID) {
        addPage(folderID: folderID, notebookID: notebookID, style: .blank)
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
    func setPDFDrawing(
        folderID: UUID,
        notebookID: UUID,
        pageID: UUID,
        pageIndex: Int,
        data: Data?
    ) {
        updatePage(folderID: folderID, notebookID: notebookID, pageID: pageID) {
            $0.drawingPerPDFPage[pageIndex] = data
        }
    }
}
