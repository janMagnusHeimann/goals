import SwiftUI
import Charts

struct ReadingStatsView: View {
    let goal: Goal

    private var books: [Book] {
        goal.sortedBooks
    }

    private var completedBooks: [Book] {
        goal.completedBooks
    }

    private var currentlyReading: [Book] {
        books.filter { $0.isCurrentlyReading }
    }

    private var totalPagesRead: Int {
        books.reduce(0) { $0 + $1.currentPage }
    }

    private var totalReadingStreak: Int {
        // Calculate overall reading streak from all books
        let allSessions = books.flatMap { $0.sortedReadingSessions }
            .sorted { $0.date > $1.date }

        let calendar = Calendar.current
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())

        let sessionDates = Set(allSessions.map { calendar.startOfDay(for: $0.date) })

        while sessionDates.contains(currentDate) {
            streak += 1
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
        }

        return streak
    }

    private var averagePagesPerDay: Double {
        let totalDays = Calendar.current.dateComponents(
            [.day],
            from: goal.startDate,
            to: Date()
        ).day ?? 1
        return Double(totalPagesRead) / Double(max(1, totalDays))
    }

    private var pagesThisWeek: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        return books
            .flatMap { $0.sortedReadingSessions }
            .filter { $0.date >= weekAgo }
            .reduce(0) { $0 + $1.pagesRead }
    }

    var body: some View {
        VStack(spacing: 20) {
            // Stats Cards Row
            HStack(spacing: 16) {
                StatCard(
                    value: totalPagesRead,
                    label: "Pages Read",
                    icon: "doc.text.fill",
                    color: .blue
                )

                StatCard(
                    value: completedBooks.count,
                    label: "Books Completed",
                    icon: "checkmark.circle.fill",
                    color: .green
                )

                StatCard(
                    value: pagesThisWeek,
                    label: "This Week",
                    icon: "calendar",
                    color: .orange
                )
            }

            HStack(spacing: 16) {
                // Reading Streak Card
                StreakCard(
                    title: "Reading Streak",
                    currentStreak: totalReadingStreak,
                    longestStreak: totalReadingStreak, // TODO: Track longest
                    icon: "flame.fill"
                )

                // Average Pace Card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "speedometer")
                            .foregroundStyle(.purple)
                        Text("Reading Pace")
                            .font(.headline)
                        Spacer()
                    }

                    HStack(alignment: .bottom, spacing: 4) {
                        Text(String(format: "%.1f", averagePagesPerDay))
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                        Text("pages/day")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.bottom, 4)
                    }

                    // On track indicator
                    let onTrack = isOnTrack
                    HStack(spacing: 4) {
                        Image(systemName: onTrack ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundStyle(onTrack ? .green : .orange)
                        Text(onTrack ? "On track for goal" : "Behind schedule")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .background(Color.goalCardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // Reading Activity Chart
            if !readingActivityData.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Reading Activity")
                        .font(.headline)

                    Chart(readingActivityData, id: \.date) { item in
                        BarMark(
                            x: .value("Date", item.date, unit: .day),
                            y: .value("Pages", item.pages)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .cornerRadius(4)
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                            AxisGridLine()
                            AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                        }
                    }
                    .frame(height: 150)
                }
                .padding()
                .background(Color.goalCardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var isOnTrack: Bool {
        let daysElapsed = Calendar.current.dateComponents([.day], from: goal.startDate, to: Date()).day ?? 0
        let daysTotal = goal.daysRemaining + daysElapsed
        guard daysTotal > 0 else { return true }

        let expectedProgress = Double(daysElapsed) / Double(daysTotal)
        let actualProgress = goal.progress

        return actualProgress >= expectedProgress * 0.9 // Within 10% of expected
    }

    private var readingActivityData: [(date: Date, pages: Int)] {
        let calendar = Calendar.current
        let fourWeeksAgo = calendar.date(byAdding: .day, value: -28, to: Date())!

        let allSessions = books.flatMap { $0.sortedReadingSessions }
            .filter { $0.date >= fourWeeksAgo }

        // Group by day
        var dailyPages: [Date: Int] = [:]
        for session in allSessions {
            let day = calendar.startOfDay(for: session.date)
            dailyPages[day, default: 0] += session.pagesRead
        }

        // Fill in missing days with 0
        var result: [(date: Date, pages: Int)] = []
        var currentDate = fourWeeksAgo
        while currentDate <= Date() {
            let day = calendar.startOfDay(for: currentDate)
            result.append((date: day, pages: dailyPages[day] ?? 0))
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }

        return result
    }
}

// MARK: - Reading Progress Summary

struct ReadingProgressSummary: View {
    let goal: Goal

    private var completedCount: Int {
        goal.completedBooks.count
    }

    private var inProgressCount: Int {
        goal.booksInProgress.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "books.vertical.fill")
                    .foregroundStyle(.blue)
                Text("Progress Summary")
                    .font(.headline)
                Spacer()
            }

            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(completedCount)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.green)
                    Text("Completed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(inProgressCount)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.blue)
                    Text("In Progress")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Goal progress ring
                AnimatedProgressRing(progress: goal.progress, color: .blue, lineWidth: 8)
                    .frame(width: 70, height: 70)
            }

            // Goal status
            HStack {
                Text("\(completedCount) of \(goal.targetValue) books")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(goal.daysRemaining) days left")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color.goalCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Stat Card (Local)

private struct StatCard: View {
    let value: Int
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text("\(value)")
                .font(.system(size: 28, weight: .bold, design: .rounded))

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.goalCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Preview

#Preview {
    let goal = Goal(title: "Read 24 Books", goalType: .bookReading, targetValue: 24)
    goal.currentValue = 8

    return ScrollView {
        VStack(spacing: 20) {
            ReadingProgressSummary(goal: goal)
            ReadingStatsView(goal: goal)
        }
        .padding()
    }
    .frame(width: 600, height: 800)
}
