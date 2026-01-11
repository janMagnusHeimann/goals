import Foundation
import SwiftData

@Model
final class StarHistory {
    var id: UUID = UUID()
    var date: Date = Date()
    var starCount: Int = 0
    var forkCount: Int = 0
    var watcherCount: Int = 0
    var openIssuesCount: Int = 0
    var createdAt: Date = Date()

    var repository: GitHubRepository?

    init(
        date: Date = Date(),
        starCount: Int = 0,
        forkCount: Int = 0,
        watcherCount: Int = 0,
        openIssuesCount: Int = 0
    ) {
        self.date = date
        self.starCount = starCount
        self.forkCount = forkCount
        self.watcherCount = watcherCount
        self.openIssuesCount = openIssuesCount
    }

    // MARK: - Computed Properties

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    var formattedStarCount: String {
        formatNumber(starCount)
    }

    var formattedForkCount: String {
        formatNumber(forkCount)
    }

    // MARK: - Helpers

    private func formatNumber(_ num: Int) -> String {
        if num >= 1000 {
            return String(format: "%.1fk", Double(num) / 1000.0)
        }
        return "\(num)"
    }
}

// MARK: - Star History Extensions

extension Array where Element == StarHistory {
    var starGrowthThisWeek: Int {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()

        let recentEntries = self.filter { $0.date >= weekAgo }.sorted { $0.date < $1.date }
        guard let first = recentEntries.first, let last = recentEntries.last else { return 0 }
        return last.starCount - first.starCount
    }

    var starGrowthThisMonth: Int {
        let calendar = Calendar.current
        let monthAgo = calendar.date(byAdding: .month, value: -1, to: Date()) ?? Date()

        let recentEntries = self.filter { $0.date >= monthAgo }.sorted { $0.date < $1.date }
        guard let first = recentEntries.first, let last = recentEntries.last else { return 0 }
        return last.starCount - first.starCount
    }

    var averageDailyStarGrowth: Double {
        let sorted = self.sorted { $0.date < $1.date }
        guard sorted.count >= 2,
              let first = sorted.first,
              let last = sorted.last else { return 0 }

        let days = Calendar.current.dateComponents([.day], from: first.date, to: last.date).day ?? 1
        guard days > 0 else { return 0 }

        return Double(last.starCount - first.starCount) / Double(days)
    }

    func projectedStarsAt(date: Date) -> Int? {
        guard let current = self.sorted(by: { $0.date > $1.date }).first else { return nil }
        let avgGrowth = averageDailyStarGrowth
        let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
        return current.starCount + Int(avgGrowth * Double(days))
    }
}
