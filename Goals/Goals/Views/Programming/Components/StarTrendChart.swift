import SwiftUI
import Charts

struct StarTrendChart: View {
    let repositories: [GitHubRepository]
    var daysToShow: Int = 90

    private var chartData: [StarDataPoint] {
        var allData: [StarDataPoint] = []

        for repo in repositories {
            guard let history = repo.starHistory else { continue }

            for entry in history {
                allData.append(StarDataPoint(
                    date: entry.date,
                    starCount: entry.starCount,
                    repositoryName: repo.name
                ))
            }
        }

        return allData.sorted { $0.date < $1.date }
    }

    private var latestTotalStars: Int {
        repositories.reduce(0) { $0 + $1.stars }
    }

    private var weeklyGrowth: Int {
        repositories.reduce(0) { total, repo in
            total + ((repo.starHistory ?? []).starGrowthThisWeek)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "star.fill")
                    .font(.title2)
                    .foregroundStyle(.yellow)
                Text("Star Trends")
                    .font(.headline)
                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Text("\(latestTotalStars)")
                            .font(.title3)
                            .fontWeight(.bold)
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                    }
                    if weeklyGrowth != 0 {
                        HStack(spacing: 2) {
                            Image(systemName: weeklyGrowth > 0 ? "arrow.up" : "arrow.down")
                                .font(.caption2)
                            Text("\(abs(weeklyGrowth)) this week")
                        }
                        .font(.caption)
                        .foregroundStyle(weeklyGrowth > 0 ? .green : .red)
                    }
                }
            }

            if !chartData.isEmpty {
                Chart {
                    ForEach(chartData) { dataPoint in
                        LineMark(
                            x: .value("Date", dataPoint.date),
                            y: .value("Stars", dataPoint.starCount)
                        )
                        .foregroundStyle(by: .value("Repository", dataPoint.repositoryName))
                        .interpolationMethod(.catmullRom)

                        AreaMark(
                            x: .value("Date", dataPoint.date),
                            y: .value("Stars", dataPoint.starCount)
                        )
                        .foregroundStyle(by: .value("Repository", dataPoint.repositoryName))
                        .opacity(0.1)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month(.abbreviated))
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let count = value.as(Int.self) {
                                Text(formatNumber(count))
                                    .font(.caption)
                            }
                        }
                    }
                }
                .chartLegend(position: .bottom)
                .frame(height: 200)
            } else {
                ContentUnavailableView {
                    Label("No Star History", systemImage: "star")
                } description: {
                    Text("Star history will appear as data is collected")
                }
                .frame(height: 200)
            }

            // Repository breakdown
            if !repositories.isEmpty {
                Divider()

                VStack(spacing: 8) {
                    ForEach(repositories.sorted { $0.stars > $1.stars }) { repo in
                        RepositoryStarRow(repository: repo)
                    }
                }
            }
        }
        .padding()
        .background(Color.goalCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func formatNumber(_ num: Int) -> String {
        if num >= 1000 {
            return String(format: "%.1fk", Double(num) / 1000.0)
        }
        return "\(num)"
    }
}

// MARK: - Supporting Types

struct StarDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let starCount: Int
    let repositoryName: String
}

struct RepositoryStarRow: View {
    let repository: GitHubRepository

    private var weeklyGrowth: Int {
        (repository.starHistory ?? []).starGrowthThisWeek
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "book.closed.fill")
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(repository.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                if let language = repository.primaryLanguage {
                    Text(language)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            HStack(spacing: 8) {
                // Stars
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                    Text("\(repository.stars)")
                }
                .font(.subheadline)

                // Forks
                HStack(spacing: 4) {
                    Image(systemName: "tuningfork")
                        .foregroundStyle(.secondary)
                    Text("\(repository.forks)")
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                // Weekly growth
                if weeklyGrowth != 0 {
                    HStack(spacing: 2) {
                        Image(systemName: weeklyGrowth > 0 ? "arrow.up" : "arrow.down")
                        Text("\(abs(weeklyGrowth))")
                    }
                    .font(.caption)
                    .foregroundStyle(weeklyGrowth > 0 ? .green : .red)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background((weeklyGrowth > 0 ? Color.green : Color.red).opacity(0.1))
                    .clipShape(Capsule())
                }
            }
        }
    }
}

// MARK: - Compact Star Card

struct StarsSummaryCard: View {
    let repositories: [GitHubRepository]

    private var totalStars: Int {
        repositories.reduce(0) { $0 + $1.stars }
    }

    private var totalForks: Int {
        repositories.reduce(0) { $0 + $1.forks }
    }

    private var weeklyGrowth: Int {
        repositories.reduce(0) { total, repo in
            total + ((repo.starHistory ?? []).starGrowthThisWeek)
        }
    }

    var body: some View {
        HStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("GitHub Stats")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 4) {
                    Text("\(totalStars)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                    Image(systemName: "star.fill")
                        .font(.title2)
                        .foregroundStyle(.yellow)
                }

                Text("total stars")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 12) {
                if weeklyGrowth != 0 {
                    HStack(spacing: 4) {
                        Image(systemName: weeklyGrowth > 0 ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill")
                        Text("+\(weeklyGrowth)")
                    }
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(weeklyGrowth > 0 ? .green : .red)
                }

                HStack(spacing: 12) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(totalForks)")
                            .font(.headline)
                        Text("forks")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(repositories.count)")
                            .font(.headline)
                        Text("repos")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color.yellow.opacity(0.1), Color.goalCardBackground],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Preview

#Preview {
    // Create sample repositories
    let repo1 = GitHubRepository(name: "awesome-swift", fullName: "user/awesome-swift")
    repo1.stars = 1250
    repo1.forks = 150
    repo1.primaryLanguage = "Swift"

    let repo2 = GitHubRepository(name: "goals-tracker", fullName: "user/goals-tracker")
    repo2.stars = 340
    repo2.forks = 25
    repo2.primaryLanguage = "Swift"

    // Create star history
    let history1: [StarHistory] = (0..<30).map { daysAgo in
        StarHistory(
            date: Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!,
            starCount: 1250 - (daysAgo * 3)
        )
    }
    repo1.starHistory = history1

    let history2: [StarHistory] = (0..<30).map { daysAgo in
        StarHistory(
            date: Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!,
            starCount: 340 - (daysAgo * 1)
        )
    }
    repo2.starHistory = history2

    return VStack(spacing: 20) {
        StarsSummaryCard(repositories: [repo1, repo2])
        StarTrendChart(repositories: [repo1, repo2])
    }
    .padding()
    .frame(width: 600, height: 600)
}
