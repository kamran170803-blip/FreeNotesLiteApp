

import SwiftUI

struct FoldersView: View {
    @ObservedObject var vm: NotesViewModel
    @State private var newFolderName = ""
    @State private var showAddFolder = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(vm.folders) { folder in
                    NavigationLink(folder.name) {
                        ContentViewForFolder(vm: vm, folder: folder)
                    }
                }
                .onDelete { indexSet in
                    indexSet.map { vm.folders[$0] }.forEach(vm.deleteFolder)
                }
            }
            .navigationTitle("Folders")
            .toolbar {
                Button {
                    showAddFolder = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            .alert("New Folder", isPresented: $showAddFolder) {
                TextField("Folder name", text: $newFolderName)
                Button("Add") {
                    vm.addFolder(name: newFolderName)
                    newFolderName = ""
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
}
