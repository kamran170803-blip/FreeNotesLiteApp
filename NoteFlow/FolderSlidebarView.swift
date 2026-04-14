import SwiftUI

struct FoldersSidebarView: View {
    @ObservedObject var vm: NotesViewModel
    @State private var selectedFolder: Folder?

    var body: some View {
        List(selection: $selectedFolder) {

            Section("Folders") {
                ForEach(vm.folders) { folder in
                    NavigationLink(value: folder) {
                        HStack {
                            Image(systemName: "folder")
                            Text(folder.name)
                            Spacer()
                            Text("\(vm.notes.filter { $0.folderID == folder.id }.count)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Folders")
        .navigationDestination(for: Folder.self) { folder in
            ContentViewForFolder(vm: vm, folder: folder)
        }
    }
}
