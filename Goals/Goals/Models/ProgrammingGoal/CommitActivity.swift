import SwiftData
import Foundation

@Model
final class CommitActivity {
    var id: UUID = UUID()
    var weekStartDate: Date = Date()
    var commitCount: Int = 0
    var additions: Int = 0
    var deletions: Int = 0

    var repository: GitHubRepository?

    var weekLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: weekStartDate)
    }

    var netChanges: Int {
        additions - deletions
    }

    var hasActivity: Bool {
        commitCount > 0
    }

    init(weekStartDate: Date, commitCount: Int, additions: Int = 0, deletions: Int = 0) {
        self.weekStartDate = weekStartDate
        self.commitCount = commitCount
        self.additions = additions
        self.deletions = deletions
    }
}
