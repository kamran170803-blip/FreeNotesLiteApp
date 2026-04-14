import Foundation

struct Note: Identifiable, Codable, Hashable {
    var id: UUID
    var title: String
    var content: String
    var isPinned: Bool
    var colorIndex: Int
    var createdAt: Date
    var updatedAt: Date
    var folderID: UUID?
    var drawingData: Data = Data()
    init(
        id: UUID = UUID(),
        title: String = "",
        content: String = "",
        isPinned: Bool = false,
        colorIndex: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.isPinned = isPinned
        self.colorIndex = colorIndex
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var displayTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Untitled Note" : title
    }

    var previewText: String {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "No content yet" }
        return String(trimmed.prefix(120))
    }
}

extension String {
    var trimmedText: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var isBlank: Bool {
        trimmedText.isEmpty
    }
}
        

