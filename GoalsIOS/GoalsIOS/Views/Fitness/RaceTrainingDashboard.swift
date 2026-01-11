import SwiftUI
import Charts

struct RaceTrainingDashboard: View {
    let goal: Goal
    let config: FitnessGoalConfig

    private var sessions: [TrainingSession] {
        goal.sortedTrainingSessions
    }

    private var runningSessions: [TrainingSession] {
        sessions.filter { $0.workoutType == .run }
    }

    private var currentPace: Int? {
        let recentRuns = runningSessions
            .filter { $0.effectivePace != nil }
            .prefix(5)
        guard !recentRuns.isEmpty else { return nil }
        let totalPace = recentRuns.compactMap { $0.effectivePace }.reduce(0, +)
        return totalPace / recentRuns.count
    }

    private var recentPaces: [Int] {
        Array(runningSessions
            .compactMap { $0.effectivePace }
            .prefix(10)
            .reversed())
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Race Countdown Header
                RaceCountdownCard(config: config)

                // Pace Comparison
                if let targetPace = config.targetPaceSecondsPerKm {
                    PaceComparisonCard(
                        targetPaceSecondsPerKm: targetPace,
                        currentPaceSecondsPerKm: currentPace,
                        recentPaces: recentPaces
                    )
                }

                // Training Phase Timeline
                TrainingPhaseTimeline(config: config)

                // Weekly Mileage Chart
                WeeklyMileageChart(
                    sessions: sessions,
                    targetMileageKm: config.weeklyMileageTargetKm
                )

                // Long Run Progression
                LongRunProgressionCard(sessions: runningSessions)

                // Recent Workouts
                RecentWorkoutsCard(sessions: Array(sessions.prefix(5)))

                // Race Prediction
                if let targetPace = config.targetPaceSecondsPerKm,
                   let raceType = config.raceType {
                    RacePredictionCard(
                        raceType: raceType,
                        targetPace: targetPace,
                        currentPace: currentPace,
                        recentSessions: Array(runningSessions.prefix(10))
                    )
                }
            }
            .padding()
        }
    }
}

// MARK: - Race Countdown Card

struct RaceCountdownCard: View {
    let config: FitnessGoalConfig

    var body: some View {
        HStack(spacing: 24) {
            // Race Info
            VStack(alignment: .leading, spacing: 8) {
                if let raceName = config.raceName {
                    Text(raceName)
                        .font(.title2)
                        .fontWeight(.bold)
                } else if let raceType = config.raceType {
                    Text(raceType.displayName)
                        .font(.title2)
                        .fontWeight(.bold)
                }

                if let raceDate = config.raceDate {
                    Text(raceDate, style: .date)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if let phase = config.currentPhase {
                    PhaseBadge(phase: phase)
                }
            }

            Spacer()

            // Countdown
            if let days = config.daysUntilRace {
                VStack(spacing: 4) {
                    Text("\(days)")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundStyle(.orange)
                    Text("days to go")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            // Target Time
            if let targetTime = config.targetFinishTimeFormatted {
                VStack(spacing: 4) {
                    Text("Goal")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(targetTime)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.green)
                }
            }
        }
        .padding(24)
        .background(
            LinearGradient(
                colors: [Color.orange.opacity(0.1), Color.goalCardBackground],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Long Run Progression Card

struct LongRunProgressionCard: View {
    let sessions: [TrainingSession]

    private var longRuns: [TrainingSession] {
        sessions
            .filter { ($0.workoutIntent == .longRun || ($0.distanceKm ?? 0) >= 15) }
            .sorted { $0.date < $1.date }
    }

    private var longestRun: Double {
        longRuns.compactMap { $0.distanceKm }.max() ?? 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "road.lanes")
                    .font(.title2)
                    .foregroundStyle(.blue)
                Text("Long Run Progression")
                    .font(.headline)
                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%.1f km", longestRun))
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("longest")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if !longRuns.isEmpty {
                Chart(longRuns.suffix(10)) { session in
                    if let distance = session.distanceKm {
                        BarMark(
                            x: .value("Date", session.date, unit: .day),
                            y: .value("Distance", distance)
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
                }
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    }
                }
                .frame(height: 120)
            } else {
                ContentUnavailableView {
                    Label("No Long Runs Yet", systemImage: "road.lanes")
                } description: {
                    Text("Complete runs of 15km or more to track progression")
                }
                .frame(height: 120)
            }
        }
        .padding()
        .background(Color.goalCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Recent Workouts Card

struct RecentWorkoutsCard: View {
    let sessions: [TrainingSession]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.title2)
                    .foregroundStyle(.purple)
                Text("Recent Workouts")
                    .font(.headline)
                Spacer()
            }

            ForEach(sessions) { session in
                WorkoutRow(session: session)
                if session.id != sessions.last?.id {
                    Divider()
                }
            }
        }
        .padding()
        .background(Color.goalCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct WorkoutRow: View {
    let session: TrainingSession

    var body: some View {
        HStack(spacing: 12) {
            // Workout type icon
            Image(systemName: session.workoutType.icon)
                .font(.title3)
                .foregroundStyle(session.workoutType.color)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(session.displayTitle)
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 8) {
                    Text(session.date, style: .date)
                    if let intent = session.workoutIntent {
                        Text("•")
                        Text(intent.displayName)
                            .foregroundStyle(intent.color)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                if let distance = session.formattedDistance {
                    Text(distance)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                if let pace = session.formattedPace {
                    Text(pace)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

// MARK: - Race Prediction Card

struct RacePredictionCard: View {
    let raceType: RaceType
    let targetPace: Int
    let currentPace: Int?
    let recentSessions: [TrainingSession]

    private var predictedFinishTime: Int? {
        guard let pace = currentPace else { return nil }
        return Int(raceType.distanceKm * Double(pace))
    }

    private var targetFinishTime: Int {
        Int(raceType.distanceKm * Double(targetPace))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "trophy.fill")
                    .font(.title2)
                    .foregroundStyle(.yellow)
                Text("Race Prediction")
                    .font(.headline)
                Spacer()
            }

            HStack(spacing: 32) {
                VStack(spacing: 4) {
                    Text("Goal Time")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(formatTime(targetFinishTime))
                        .font(.title2)
                        .fontWeight(.bold)
                }

                if let predicted = predictedFinishTime {
                    VStack(spacing: 4) {
                        Text("Predicted")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(formatTime(predicted))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(predicted <= targetFinishTime ? .green : .orange)
                    }

                    VStack(spacing: 4) {
                        Text("Difference")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(formatTimeDifference(predicted - targetFinishTime))
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(predicted <= targetFinishTime ? .green : .orange)
                    }
                }
            }

            Text("Based on your recent \(raceType.displayName) pace training")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color.goalCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func formatTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%d:%02d", minutes, secs)
    }

    private func formatTimeDifference(_ seconds: Int) -> String {
        let sign = seconds > 0 ? "+" : ""
        let absSeconds = abs(seconds)
        let minutes = absSeconds / 60
        let secs = absSeconds % 60
        return String(format: "%@%d:%02d", sign, minutes, secs)
    }
}

// MARK: - Preview

#Preview {
    let goal = Goal(title: "Marathon Training", goalType: .fitness, targetValue: 150)

    let config = FitnessGoalConfig(fitnessGoalType: .raceTraining)
    config.raceType = .marathon
    config.raceName = "Berlin Marathon 2026"
    config.raceDate = Calendar.current.date(byAdding: .day, value: 90, to: Date())
    config.targetPaceSecondsPerKm = 330 // 5:30/km
    config.targetFinishTimeSeconds = 13950 // 3:52:30
    config.currentPhase = .build
    config.weeklyMileageTargetKm = 60
    goal.fitnessConfig = config

    return RaceTrainingDashboard(goal: goal, config: config)
        .frame(width: 700, height: 900)
}
