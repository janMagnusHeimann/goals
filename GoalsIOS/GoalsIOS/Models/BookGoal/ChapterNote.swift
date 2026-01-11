import SwiftData
import Foundation

@Model
final class ChapterNote {
    var id: UUID = UUID()
    var content: String = ""
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var pageNumber: Int?
    var highlightColor: String?

    var chapter: Chapter?

    var isEmpty: Bool {
        content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var preview: String {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count <= 100 {
            return trimmed
        }
        return String(trimmed.prefix(100)) + "..."
    }

    init(content: String = "") {
        self.content = content
    }

    func update(content: String) {
        self.content = content
        self.updatedAt = Date()
    }
}
