import SwiftData
import Foundation

@Model
final class GitHubRepository {
    var id: UUID = UUID()
    var repoId: Int = 0
    var name: String = ""
    var fullName: String = ""
    var repoDescription: String?
    var htmlURL: String = ""
    var language: String?
    var starCount: Int = 0
    var forkCount: Int = 0
    var openIssuesCount: Int = 0
    var lastSyncedAt: Date?
    var createdAt: Date = Date()
    var isPrivate: Bool = false
    var defaultBranch: String = "main"

    var goal: Goal?

    @Relationship(deleteRule: .cascade, inverse: \CommitActivity.repository)
    var commitActivities: [CommitActivity]? = []

    var totalCommits: Int {
        (commitActivities ?? []).reduce(0) { $0 + $1.commitCount }
    }

    var totalAdditions: Int {
        (commitActivities ?? []).reduce(0) { $0 + $1.additions }
    }

    var totalDeletions: Int {
        (commitActivities ?? []).reduce(0) { $0 + $1.deletions }
    }

    var recentCommits: Int {
        let fourWeeksAgo = Calendar.current.date(byAdding: .weekOfYear, value: -4, to: Date()) ?? Date()
        return (commitActivities ?? [])
            .filter { $0.weekStartDate >= fourWeeksAgo }
            .reduce(0) { $0 + $1.commitCount }
    }

    var sortedCommitActivities: [CommitActivity] {
        (commitActivities ?? []).sorted { $0.weekStartDate > $1.weekStartDate }
    }

    var ownerName: String {
        fullName.components(separatedBy: "/").first ?? ""
    }

    var repoName: String {
        fullName.components(separatedBy: "/").last ?? name
    }

    var needsSync: Bool {
        guard let lastSync = lastSyncedAt else { return true }
        let hoursSinceSync = Calendar.current.dateComponents([.hour], from: lastSync, to: Date()).hour ?? 0
        return hoursSinceSync >= 1
    }

    init(repoId: Int, name: String, fullName: String, htmlURL: String) {
        self.repoId = repoId
        self.name = name
        self.fullName = fullName
        self.htmlURL = htmlURL
    }

    func updateFromAPI(description: String?, language: String?, stars: Int, forks: Int, issues: Int, isPrivate: Bool) {
        self.repoDescription = description
        self.language = language
        self.starCount = stars
        self.forkCount = forks
        self.openIssuesCount = issues
        self.isPrivate = isPrivate
        self.lastSyncedAt = Date()
    }
}
