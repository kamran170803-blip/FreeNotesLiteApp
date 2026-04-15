import SwiftUI

struct FolderListView: View {
    @EnvironmentObject var store: NotesStore
    @State private var selectedFolderID: UUID?
    @State private var showingAddFolder = false
    @State private var folderName = ""

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedFolderID) {
                Section {
                    ForEach(store.folders) { folder in
                        Label {
                            Text(folder.name)
                                .font(.headline)
                        } icon: {
                            Image(systemName: "folder.fill")
                                .foregroundStyle(.blue)
                        }
                        .tag(folder.id)
                    }
                } header: {
                    Text("Folders")
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("FreeNotes Lite")
            .toolbar {
                Button {
                    folderName = ""
                    showingAddFolder = true
                } label: {
                    Label("Add Folder", systemImage: "folder.badge.plus")
                }
            }
            .sheet(isPresented: $showingAddFolder) {
                TextInputSheet(
                    title: "New Folder",
                    placeholder: "Folder name",
                    primaryButtonTitle: "Create",
                    onCancel: {}
                ) { name in
                    store.folders.append(NoteFolder(name: name))
                    selectedFolderID = store.folders.last?.id
                }
            }
            .onAppear {
                if selectedFolderID == nil {
                    selectedFolderID = store.folders.first?.id
                }
            }
        } detail: {
            if let folderID = selectedFolderID {
                NavigationStack {
                    NotebookListView(folderID: folderID)
                }
            } else {
                ContentUnavailableView(
                    "Select a Folder",
                    systemImage: "folder",
                    description: Text("Create a folder to begin.")
                )
            }
        }
    }
}
