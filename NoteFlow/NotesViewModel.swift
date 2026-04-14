import Foundation
import SwiftUI
import Combine


@MainActor
final class NotesViewModel: ObservableObject {
    @Published var notes: [Note] = []
    @Published var folders: [Folder] = []
    private let fileName = "notes.json"
    
    init() {
        loadNotes()
        loadFolders()
    }
    
    private var fileURL: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documents.appendingPathComponent(fileName)
    }
    
    func loadNotes() {
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            notes = try decoder.decode([Note].self, from: data)
            sortNotes()
        } catch {
            notes = []
        }
    }
    
    func saveNotes() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(notes)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            print("Save error:", error.localizedDescription)
        }
    }
    
    func addOrUpdate(_ note: Note) {
        var updated = note
        updated.updatedAt = Date()
        
        if let index = notes.firstIndex(where: { $0.id == updated.id }) {
            notes[index] = updated
        } else {
            notes.append(updated)
        }
        
        sortNotes()
        saveNotes()
    }
    
    func delete(_ note: Note) {
        notes.removeAll { $0.id == note.id }
        saveNotes()
    }
    
    func togglePin(_ note: Note) {
        guard let index = notes.firstIndex(where: { $0.id == note.id }) else { return }
        notes[index].isPinned.toggle()
        notes[index].updatedAt = Date()
        sortNotes()
        saveNotes()
    }
    
    private func sortNotes() {
        notes.sort {
            if $0.isPinned != $1.isPinned {
                return $0.isPinned && !$1.isPinned
            }
            return $0.updatedAt > $1.updatedAt
        }
    }
    
    func addFolder(name: String) {
        let newFolder = Folder(name: name)
        folders.append(newFolder)
        saveFolders()
    }
    
    func deleteFolder(_ folder: Folder) {
        folders.removeAll { $0.id == folder.id }
        notes.removeAll { $0.folderID == folder.id } // delete notes inside
        saveNotes()
        saveFolders()
    }
    private var folderURL: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documents.appendingPathComponent("folders.json")
    }
    
    func saveFolders() {
        do {
            let data = try JSONEncoder().encode(folders)
            try data.write(to: folderURL)
        } catch {
            print("Folder save error")
        }
    }
    
    func loadFolders() {
        do {
            let data = try Data(contentsOf: folderURL)
            folders = try JSONDecoder().decode([Folder].self, from: data)
        } catch {
            folders = []
        }
    }
}
