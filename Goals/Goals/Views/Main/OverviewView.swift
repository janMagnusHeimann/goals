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
        ScrollView {
            VStack(spacing: 24) {
                // Year Header
                YearHeaderCard()

                // Stats Summary
                HStack(spacing: 16) {
                    StatCard(
                        value: totalBooks,
                        label: "Books Read",
                        icon: "book.fill",
                        color: .blue
                    )

                    StatCard(
                        value: totalSessions,
                        label: "Training Sessions",
                        icon: "figure.run",
                        color: .orange
                    )

                    StatCard(
                        value: totalCommits,
                        label: "Commits",
                        icon: "chevron.left.forwardslash.chevron.right",
                        color: .purple
                    )
                }

                // Goals Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(activeGoals) { goal in
                        OverviewGoalCard(goal: goal)
                    }
                }

                if activeGoals.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "target")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)

                        Text("No Goals Yet")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("Create your first goal to start tracking your \(Goal.currentYear) progress")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                }

                Spacer(minLength: 40)
            }
            .padding(24)
        }
        .background(Color.goalSecondaryBackground)
        .navigationTitle("\(Goal.currentYear) Goals")
    }
}

// MARK: - Year Header Card (macOS)

struct YearHeaderCard: View {
    var body: some View {
        HStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("\(Goal.currentYear)")
                    .font(.system(size: 56, weight: .bold, design: .rounded))

                Text("\(Goal.daysRemainingInYear) days remaining")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Year progress visualization
            VStack(alignment: .trailing, spacing: 8) {
                ZStack {
                    Circle()
                        .stroke(Color.blue.opacity(0.2), lineWidth: 12)

                    Circle()
                        .trim(from: 0, to: Goal.yearProgress)
                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 2) {
                        Text("\(Int(Goal.yearProgress * 100))%")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("of year")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 100, height: 100)
            }
        }
        .padding(24)
        .background(Color.goalCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let value: Int
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title)
                .foregroundStyle(color)

            Text("\(value)")
                .font(.system(size: 36, weight: .bold, design: .rounded))

            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color.goalCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Overview Goal Card

struct OverviewGoalCard: View {
    let goal: Goal

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: goal.goalType.icon)
                    .font(.title2)
                    .foregroundStyle(Color.forGoalType(goal.goalType))

                Spacer()

                Text("\(goal.progressPercentage)%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.forGoalType(goal.goalType))
            }

            Text(goal.title)
                .font(.headline)
                .lineLimit(2)

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
        .padding(16)
        .background(Color.goalCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    OverviewView()
        .modelContainer(for: Goal.self, inMemory: true)
        .frame(width: 800, height: 600)
}
