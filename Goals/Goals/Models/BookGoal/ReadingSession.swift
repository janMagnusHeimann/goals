import Foundation
import SwiftData

@Model
final class ReadingSession {
    var id: UUID = UUID()
    var date: Date = Date()
    var pagesRead: Int = 0
    var durationMinutes: Int = 0
    var startPage: Int = 0
    var endPage: Int = 0
    var notes: String?
    var createdAt: Date = Date()

    var book: Book?

    init(
        pagesRead: Int = 0,
        durationMinutes: Int = 0,
        startPage: Int = 0,
        endPage: Int = 0,
        date: Date = Date(),
        notes: String? = nil
    ) {
        self.pagesRead = pagesRead
        self.durationMinutes = durationMinutes
        self.startPage = startPage
        self.endPage = endPage
        self.date = date
        self.notes = notes
    }

    // MARK: - Computed Properties

    var pagesPerHour: Double {
        guard durationMinutes > 0 else { return 0 }
        return Double(pagesRead) / (Double(durationMinutes) / 60.0)
    }

    var formattedDuration: String {
        let hours = durationMinutes / 60
        let minutes = durationMinutes % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
