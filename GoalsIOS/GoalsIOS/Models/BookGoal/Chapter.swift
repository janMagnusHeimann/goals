import SwiftData
import Foundation

@Model
final class Chapter {
    var id: UUID = UUID()
    var title: String = ""
    var orderIndex: Int = 0
    var isCompleted: Bool = false
    var createdAt: Date = Date()
    var pageStart: Int?
    var pageEnd: Int?

    var book: Book?

    @Relationship(deleteRule: .cascade, inverse: \ChapterNote.chapter)
    var notes: [ChapterNote]? = []

    var sortedNotes: [ChapterNote] {
        (notes ?? []).sorted { $0.createdAt < $1.createdAt }
    }

    var hasNotes: Bool {
        !(notes ?? []).isEmpty
    }

    var notesCount: Int {
        notes?.count ?? 0
    }

    var pageRange: String? {
        guard let start = pageStart else { return nil }
        if let end = pageEnd {
            return "pp. \(start)-\(end)"
        }
        return "p. \(start)"
    }

    init(title: String, orderIndex: Int) {
        self.title = title
        self.orderIndex = orderIndex
    }

    func toggleCompleted() {
        isCompleted.toggle()
    }
}
