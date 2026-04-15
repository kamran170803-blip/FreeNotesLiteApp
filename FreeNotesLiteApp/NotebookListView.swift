import SwiftUI

struct NotebookListView: View {
    @EnvironmentObject var store: NotesStore
    let folderID: UUID

    @State private var showingAddNotebook = false

    var body: some View {
        if let folder = store.folder(id: folderID) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header(folder: folder)

                    if folder.notebooks.isEmpty {
                        ContentUnavailableView(
                            "No Notebooks Yet",
                            systemImage: "book.closed",
                            description: Text("Tap the plus button to create your first notebook.")
                        )
                        .frame(maxWidth: .infinity, minHeight: 280)
                    } else {
                        LazyVGrid(
                            columns: [GridItem(.adaptive(minimum: 160), spacing: 16)],
                            spacing: 16
                        ) {
                            ForEach(folder.notebooks) { notebook in
                                NavigationLink {
                                    PageView(folderID: folderID, notebookID: notebook.id)
                                } label: {
                                    NotebookCardView(notebook: notebook)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(folder.name)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddNotebook = true
                    } label: {
                        Label("Add Notebook", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddNotebook) {
                NotebookCreationSheet { title, cover, template in
                    store.addNotebook(folderID: folderID, title: title, cover: cover, template: template)
                }
            }
        } else {
            ContentUnavailableView("Folder Not Found", systemImage: "exclamationmark.triangle")
        }
    }

    private func header(folder: NoteFolder) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your Notebooks")
                .font(.largeTitle.weight(.bold))
            Text("\(folder.notebooks.count) notebook(s)")
                .foregroundStyle(.secondary)
        }
        .padding(.bottom, 8)
    }
}

// MARK: - Notebook Card View
private struct NotebookCardView: View {
    let notebook: Notebook

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(coverGradient)
                    .aspectRatio(3/4, contentMode: .fit)
                Image(systemName: notebook.cover.imageName)
                    .font(.largeTitle)
                    .foregroundColor(.white.opacity(0.8))
            }
            .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(notebook.title)
                    .font(.headline)
                    .lineLimit(2)
                    .foregroundColor(.primary)
                HStack {
                    Image(systemName: "doc.on.doc")
                        .font(.caption2)
                    Text("\(notebook.pages.count) pages")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 4)
        }
        .padding(8)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }

    private var coverGradient: LinearGradient {
        switch notebook.cover {
        case .none:
            return LinearGradient(colors: [.gray.opacity(0.3), .gray.opacity(0.2)], startPoint: .top, endPoint: .bottom)
        case .leather:
            return LinearGradient(colors: [.brown, .brown.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .fabric:
            return LinearGradient(colors: [.blue, .purple], startPoint: .top, endPoint: .bottom)
        case .geometric:
            return LinearGradient(colors: [.orange, .pink], startPoint: .leading, endPoint: .trailing)
        case .abstract:
            return LinearGradient(colors: [.green, .mint], startPoint: .top, endPoint: .bottomTrailing)
        }
    }
}
