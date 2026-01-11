import SwiftUI
import SwiftData

struct OverviewView: View {
    @Query private var allGoals: [Goal]

    private var activeGoals: [Goal] {
        allGoals.filter { !$0.isArchived && $0.isCurrentYear }
    }

    private var bookGoals: [Goal] {
        activeGoals.filter { $0.goalType == .bookReading }
    }

    private var fitnessGoals: [Goal] {
        activeGoals.filter { $0.goalType == .fitness }
    }

    private var programmingGoals: [Goal] {
        activeGoals.filter { $0.goalType == .programming }
    }

    private var totalBooks: Int {
        bookGoals.reduce(0) { $0 + $1.currentValue }
    }

    private var totalSessions: Int {
        fitnessGoals.reduce(0) { $0 + $1.currentValue }
    }

    private var totalCommits: Int {
        programmingGoals.reduce(0) { $0 + $1.currentValue }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Year Header
                    YearHeaderCard()

                    // Stats Summary
                    StatsSummaryCard(
                        books: totalBooks,
                        sessions: totalSessions,
                        commits: totalCommits
                    )

                    // Goals by Type
                    if !bookGoals.isEmpty {
                        GoalTypeSection(
                            type: .bookReading,
                            goals: bookGoals
                        )
                    }

                    if !fitnessGoals.isEmpty {
                        GoalTypeSection(
                            type: .fitness,
                            goals: fitnessGoals
                        )
                    }

                    if !programmingGoals.isEmpty {
                        GoalTypeSection(
                            type: .programming,
                            goals: programmingGoals
                        )
                    }

                    if activeGoals.isEmpty {
                        EmptyStateView(
                            title: "No Goals Yet",
                            message: "Create your first goal in the Books, Fitness, or Code tabs",
                            systemImage: "target"
                        )
                        .padding(.top, 40)
                    }
                }
                .padding()
            }
            .navigationTitle("\(Goal.currentYear) Goals")
            .background(Color(.systemGroupedBackground))
        }
    }
}

// MARK: - Year Header Card

struct YearHeaderCard: View {
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(Goal.currentYear)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))

                    Text("\(Goal.daysRemainingInYear) days remaining")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Year progress ring
                ZStack {
                    Circle()
                        .stroke(Color.blue.opacity(0.2), lineWidth: 8)

                    Circle()
                        .trim(from: 0, to: Goal.yearProgress)
                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))

                    Text("\(Int(Goal.yearProgress * 100))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .frame(width: 60, height: 60)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.blue.opacity(0.2))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.blue)
                        .frame(width: geometry.size.width * Goal.yearProgress, height: 8)
                }
            }
            .frame(height: 8)

            HStack {
                Text("Jan 1")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Dec 31")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Stats Summary Card

struct StatsSummaryCard: View {
    let books: Int
    let sessions: Int
    let commits: Int

    var body: some View {
        HStack(spacing: 0) {
            StatItem(
                value: books,
                label: "Books",
                icon: "book.fill",
                color: .blue
            )

            Divider()
                .frame(height: 40)

            StatItem(
                value: sessions,
                label: "Sessions",
                icon: "figure.run",
                color: .orange
            )

            Divider()
                .frame(height: 40)

            StatItem(
                value: commits,
                label: "Commits",
                icon: "chevron.left.forwardslash.chevron.right",
                color: .purple
            )
        }
        .padding(.vertical, 16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct StatItem: View {
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
                .font(.title2)
                .fontWeight(.bold)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Goal Type Section

struct GoalTypeSection: View {
    let type: GoalType
    let goals: [Goal]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: type.icon)
                    .foregroundStyle(Color.forGoalType(type))
                Text(type.displayName)
                    .font(.headline)
                Spacer()
                Text("\(goals.count) goal\(goals.count == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ForEach(goals) { goal in
                OverviewGoalRow(goal: goal)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct OverviewGoalRow: View {
    let goal: Goal

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(goal.title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Text("\(goal.progressPercentage)%")
                    .font(.subheadline)
                    .foregroundStyle(Color.forGoalType(goal.goalType))
            }

            ProgressView(value: goal.progress)
                .tint(Color.forGoalType(goal.goalType))

            HStack {
                Text("\(goal.currentValue) / \(goal.targetValue)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(goal.daysRemaining) days left")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    OverviewView()
        .modelContainer(for: Goal.self, inMemory: true)
}
