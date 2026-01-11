import SwiftData
import Foundation

@Model
final class Book {
    var id: UUID = UUID()
    var title: String = ""
    var author: String?
    var isbn: String?
    var coverURL: String?
    var bookDescription: String?
    var totalPages: Int?
    var currentPage: Int = 0
    var isCompleted: Bool = false
    var startDate: Date?
    var completionDate: Date?
    var notes: String?
    var createdAt: Date = Date()
    var googleBooksId: String?

    // New reading tracking properties
    var startedReadingDate: Date?
    var lastReadDate: Date?
    var dailyPageGoal: Int?

    var goal: Goal?

    @Relationship(deleteRule: .cascade, inverse: \Chapter.book)
    var chapters: [Chapter]? = []

    @Relationship(deleteRule: .cascade, inverse: \ReadingSession.book)
    var readingSessions: [ReadingSession]? = []

    var sortedChapters: [Chapter] {
        (chapters ?? []).sorted { $0.orderIndex < $1.orderIndex }
    }

    var readingProgress: Double {
        guard let total = totalPages, total > 0 else { return 0 }
        return Double(currentPage) / Double(total)
    }

    var readingProgressPercentage: Int {
        Int(readingProgress * 100)
    }

    var completedChaptersCount: Int {
        (chapters ?? []).filter { $0.isCompleted }.count
    }

    var totalChaptersCount: Int {
        chapters?.count ?? 0
    }

    var sortedReadingSessions: [ReadingSession] {
        (readingSessions ?? []).sorted { $0.date > $1.date }
    }

    // MARK: - Reading Pace & Estimates

    var pagesRemaining: Int? {
        guard let total = totalPages else { return nil }
        return max(0, total - currentPage)
    }

    var daysReading: Int {
        guard let started = startedReadingDate else { return 0 }
        return max(1, Calendar.current.dateComponents([.day], from: started, to: Date()).day ?? 1)
    }

    var averagePagesPerDay: Double {
        guard daysReading > 0 else { return 0 }
        return Double(currentPage) / Double(daysReading)
    }

    var estimatedDaysToComplete: Int? {
        guard let remaining = pagesRemaining,
              averagePagesPerDay > 0 else { return nil }
        return Int(ceil(Double(remaining) / averagePagesPerDay))
    }

    var estimatedCompletionDate: Date? {
        guard let days = estimatedDaysToComplete else { return nil }
        return Calendar.current.date(byAdding: .day, value: days, to: Date())
    }

    var totalPagesRead: Int {
        (readingSessions ?? []).reduce(0) { $0 + $1.pagesRead }
    }

    var totalReadingTimeMinutes: Int {
        (readingSessions ?? []).reduce(0) { $0 + $1.durationMinutes }
    }

    var averagePagesPerHour: Double {
        guard totalReadingTimeMinutes > 0 else { return 0 }
        return Double(totalPagesRead) / (Double(totalReadingTimeMinutes) / 60.0)
    }

    var readingStreak: Int {
        let calendar = Calendar.current
        let sessions = sortedReadingSessions
        guard !sessions.isEmpty else { return 0 }

        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())

        for session in sessions {
            let sessionDay = calendar.startOfDay(for: session.date)
            if sessionDay == currentDate {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
            } else if sessionDay < currentDate {
                break
            }
        }

        return streak
    }

    var formattedEstimatedCompletion: String? {
        guard let date = estimatedCompletionDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    var formattedPagesPerDay: String {
        String(format: "%.1f pages/day", averagePagesPerDay)
    }

    var isCurrentlyReading: Bool {
        !isCompleted && currentPage > 0
    }

    init(title: String, author: String? = nil, isbn: String? = nil) {
        self.title = title
        self.author = author
        self.isbn = isbn
    }

    func markAsCompleted() {
        isCompleted = true
        completionDate = Date()
        if let total = totalPages {
            currentPage = total
        }
    }
}
