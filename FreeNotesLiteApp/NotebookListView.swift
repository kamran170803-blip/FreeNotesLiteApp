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
                            columns: [
                                GridItem(.adaptive(minimum: 220), spacing: 16)
                            ],
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
                Button {
                    showingAddNotebook = true
                } label: {
                    Label("Add Notebook", systemImage: "plus")
                }
            }
            .sheet(isPresented: $showingAddNotebook) {
                TextInputSheet(
                    title: "New Notebook",
                    placeholder: "Notebook title",
                    primaryButtonTitle: "Create",
                    onCancel: {}
                ) { name in
                    store.addNotebook(folderID: folderID)
                    if let folderIndex = store.folders.firstIndex(where: { $0.id == folderID }) {
                        store.folders[folderIndex].notebooks[store.folders[folderIndex].notebooks.count - 1].title = name
                    }
                }
            }
        } else {
            ContentUnavailableView("Folder Not Found", systemImage: "exclamationmark.triangle")
        }
    }

    private func header(folder: NoteFolder) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Notebooks")
                .font(.title.weight(.bold))

            Text("\(folder.notebooks.count) notebook(s)")
                .foregroundStyle(.secondary)

            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.blue.opacity(0.20),
                            Color.purple.opacity(0.14),
                            Color.orange.opacity(0.10)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 120)
                .overlay(alignment: .leading) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Premium workspace")
                            .font(.headline)
                        Text("Folders, notebooks, pages, PDF import, Pencil notes, and split view.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                }
        }
    }
}

private struct NotebookCardView: View {
    let notebook: Notebook

    var body: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color(.secondarySystemBackground),
                        Color(.tertiarySystemBackground)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
            )
            .overlay(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: 10) {
                    Image(systemName: "book.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)

                    Text(notebook.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    Spacer()

                    HStack {
                        Label("\(notebook.pages.count)", systemImage: "doc.on.doc")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Text("Open")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.blue)
                    }
                }
                .padding()
            }
            .frame(height: 160)
    }
}
