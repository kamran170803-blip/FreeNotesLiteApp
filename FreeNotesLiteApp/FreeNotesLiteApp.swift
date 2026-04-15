import SwiftUI

@main
struct FreeNotesLiteApp: App {
    @StateObject private var store = NotesStore()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                FolderListView()
                
                    .environmentObject(store)
            }
        }
    }
}
