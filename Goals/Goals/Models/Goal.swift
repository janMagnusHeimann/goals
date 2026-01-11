import SwiftData
import Foundation

enum GoalType: String, Codable, CaseIterable, Identifiable {
    case bookReading = "book_reading"
    case fitness = "fitness"
    case programming = "programming"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .bookReading: return "Book Reading"
        case .fitness: return "Fitness"
        case .programming: return "Programming"
        }
    }

    var icon: String {
        switch self {
        case .bookReading: return "book.fill"
        case .fitness: return "figure.run"
        case .programming: return "chevron.left.forwardslash.chevron.right"
        }
    }

    var accentColorName: String {
        switch self {
        case .bookReading: return "blue"
        case .fitness: return "orange"
        case .programming: return "purple"
        }
    }
}

@Model
final class Goal {
    var id: UUID = UUID()
    var title: String = ""
    var goalDescription: String?
    var goalType: GoalType = GoalType.bookReading
    var targetValue: Int = 0
    var currentValue: Int = 0
    var startDate: Date = Date()
    var endDate: Date?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var isArchived: Bool = false
    var aiGeneratedStructure: String?

    @Relationship(deleteRule: .cascade, inverse: \Book.goal)
    var books: [Book]? = []

    @Relationship(deleteRule: .cascade, inverse: \TrainingSession.goal)
    var trainingSessions: [TrainingSession]? = []

    @Relationship(deleteRule: .cascade, inverse: \GitHubRepository.goal)
    var repositories: [GitHubRepository]? = []

    // New relationships for enhanced features
    @Relationship(deleteRule: .cascade, inverse: \FitnessGoalConfig.goal)
    var fitnessConfig: FitnessGoalConfig?

    @Relationship(deleteRule: .cascade, inverse: \PersonalRecord.goal)
    var personalRecords: [PersonalRecord]? = []

    @Relationship(deleteRule: .cascade, inverse: \AppProject.goal)
    var appProjects: [AppProject]? = []

    var progress: Double {
        guard targetValue > 0 else { return 0 }
        return min(Double(currentValue) / Double(targetValue), 1.0)
    }

    var progressPercentage: Int {
        Int(progress * 100)
    }

    var sortedBooks: [Book] {
        (books ?? []).sorted { ($0.createdAt) > ($1.createdAt) }
    }

    var completedBooks: [Book] {
        (books ?? []).filter { $0.isCompleted }
    }

    var sortedTrainingSessions: [TrainingSession] {
        (trainingSessions ?? []).sorted { $0.date > $1.date }
    }

    var sortedRepositories: [GitHubRepository] {
        (repositories ?? []).sorted { $0.createdAt > $1.createdAt }
    }

    var sortedPersonalRecords: [PersonalRecord] {
        (personalRecords ?? []).sorted { $0.achievedDate > $1.achievedDate }
    }

    var sortedAppProjects: [AppProject] {
        (appProjects ?? []).sorted { $0.createdAt > $1.createdAt }
    }

    // MARK: - Enhanced Book Properties

    var currentlyReadingBook: Book? {
        (books ?? []).first { !$0.isCompleted && $0.currentPage > 0 }
    }

    var booksInProgress: [Book] {
        (books ?? []).filter { !$0.isCompleted }
    }

    // MARK: - Enhanced Fitness Properties

    var isRaceTraining: Bool {
        fitnessConfig?.fitnessGoalType == .raceTraining
    }

    var totalWeeklyMileage: Double {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return (trainingSessions ?? [])
            .filter { $0.date >= weekAgo && $0.distanceUnit == .kilometers }
            .compactMap { $0.distance }
            .reduce(0, +)
    }

    var recentPaceSecondsPerKm: Int? {
        let runningSessions = (trainingSessions ?? [])
            .filter { $0.workoutType == .run && $0.paceSecondsPerKm != nil }
            .sorted { $0.date > $1.date }
            .prefix(5)
        guard !runningSessions.isEmpty else { return nil }
        let totalPace = runningSessions.compactMap { $0.paceSecondsPerKm }.reduce(0, +)
        return totalPace / runningSessions.count
    }

    // MARK: - Enhanced Programming Properties

    var totalAppRevenue: Double {
        (appProjects ?? []).reduce(0) { $0 + $1.totalRevenue }
    }

    var thisMonthAppRevenue: Double {
        (appProjects ?? []).reduce(0) { $0 + $1.thisMonthRevenue }
    }

    var totalGitHubStars: Int {
        (repositories ?? []).reduce(0) { $0 + $1.starCount }
    }

    var formattedThisMonthAppRevenue: String {
        String(format: "$%.2f", thisMonthAppRevenue)
    }

    var formattedTotalAppRevenue: String {
        String(format: "$%.2f", totalAppRevenue)
    }

    // MARK: - Year-Related Properties

    var goalYear: Int {
        Calendar.current.component(.year, from: startDate)
    }

    var daysRemaining: Int {
        guard let end = endDate else {
            // Default to end of year if no end date set
            let calendar = Calendar.current
            let year = calendar.component(.year, from: Date())
            let endOfYear = calendar.date(from: DateComponents(year: year, month: 12, day: 31))!
            return max(0, calendar.dateComponents([.day], from: Date(), to: endOfYear).day ?? 0)
        }
        return max(0, Calendar.current.dateComponents([.day], from: Date(), to: end).day ?? 0)
    }

    var isCurrentYear: Bool {
        goalYear == Calendar.current.component(.year, from: Date())
    }

    static var endOfCurrentYear: Date {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: Date())
        return calendar.date(from: DateComponents(year: year, month: 12, day: 31))!
    }

    static var currentYear: Int {
        Calendar.current.component(.year, from: Date())
    }

    static var yearProgress: Double {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: Date())
        let startOfYear = calendar.date(from: DateComponents(year: year, month: 1, day: 1))!
        let endOfYear = calendar.date(from: DateComponents(year: year, month: 12, day: 31))!
        let totalDays = Double(calendar.dateComponents([.day], from: startOfYear, to: endOfYear).day ?? 365)
        let daysPassed = Double(calendar.dateComponents([.day], from: startOfYear, to: Date()).day ?? 0)
        return daysPassed / totalDays
    }

    static var daysRemainingInYear: Int {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: Date())
        let endOfYear = calendar.date(from: DateComponents(year: year, month: 12, day: 31))!
        return max(0, calendar.dateComponents([.day], from: Date(), to: endOfYear).day ?? 0)
    }

    init(title: String, goalType: GoalType, targetValue: Int) {
        self.title = title
        self.goalType = goalType
        self.targetValue = targetValue
    }

    func updateProgress() {
        switch goalType {
        case .bookReading:
            currentValue = completedBooks.count
        case .fitness:
            currentValue = trainingSessions?.count ?? 0
        case .programming:
            currentValue = repositories?.reduce(0) { $0 + $1.totalCommits } ?? 0
        }
        updatedAt = Date()
    }
}
