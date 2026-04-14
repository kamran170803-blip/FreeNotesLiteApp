import Foundation

struct Folder: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var createdAt: Date

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
        self.createdAt = Date()
    }
}
