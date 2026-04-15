import SwiftUI

struct CompareSplitView: View {
    @EnvironmentObject var store: NotesStore
    let folderID: UUID
    let notebookID: UUID

    var body: some View {
        if let notebook = store.notebook(folderID: folderID, notebookID: notebookID) {
            HStack(spacing: 16) {
                sidePane(page: notebook.pages.first, title: "Left")
                sidePane(page: notebook.pages.dropFirst().first, title: "Right")
            }
            .padding()
            .navigationTitle("Split View")
            .navigationBarTitleDisplayMode(.inline)
        } else {
            ContentUnavailableView("Notebook Not Found", systemImage: "square.split.2x1")
        }
    }

    @ViewBuilder
    private func sidePane(page: NotePage?, title: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.secondarySystemBackground))

            if let page {
                PageContentView(
                    folderID: folderID,
                    notebookID: notebookID,
                    page: page,
                    selectedTool: .pen,          // explicitly pass defaults
                    selectedColorHex: "111111",
                    lineWidth: 4,
                    pdfPageIndex: 0
                )
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "square.dashed")
                        .font(.system(size: 30))
                    Text("No page in \(title)")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .shadow(radius: 6)
    }
}
