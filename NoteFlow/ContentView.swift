import SwiftUI

struct ContentView: View {
    @StateObject private var vm = NotesViewModel()
    
    var body : some View {
        NavigationSplitView {
                    FoldersSidebarView(vm: vm)
                } detail: {
                    Text("Select a folder")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            }
        }
