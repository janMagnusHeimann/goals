import SwiftUI
import SwiftData
import Charts

struct FitnessGoalDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var goal: Goal
    @State private var showingAddSession = false
    @State private var showingSetupSheet = false
    @State private var showingAddPRSheet = false
    @State private var selectedTimeRange: TimeRange = .month
    @State private var selectedWorkoutType: WorkoutType?
    @State private var selectedTab: FitnessTab = .overview

    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
        case all = "All"
    }

    enum FitnessTab: String, CaseIterable {
        case overview = "Overview"
        case training = "Training"
        case records = "Records"
    }

    private var isRaceTraining: Bool {
        goal.fitnessConfig?.fitnessGoalType == .raceTraining
    }

    private var filteredSessions: [TrainingSession] {
        var sessions = goal.sortedTrainingSessions

        if let type = selectedWorkoutType {
            sessions = sessions.filter { $0.workoutType == type }
        }

        let cutoffDate: Date? = {
            let calendar = Calendar.current
            switch selectedTimeRange {
            case .week:
                return calendar.date(byAdding: .weekOfYear, value: -1, to: Date())
            case .month:
                return calendar.date(byAdding: .month, value: -1, to: Date())
            case .year:
                return calendar.date(byAdding: .year, value: -1, to: Date())
            case .all:
                return nil
            }
        }()

        if let cutoff = cutoffDate {
            sessions = sessions.filter { $0.date >= cutoff }
        }

        return sessions
    }

    private var totalDuration: Int {
        filteredSessions.reduce(0) { $0 + $1.durationMinutes }
    }

    private var totalDistance: Double {
        filteredSessions.compactMap { $0.distance }.reduce(0, +)
    }

    private var workoutTypeBreakdown: [(type: WorkoutType, count: Int, duration: Int)] {
        WorkoutType.allCases.compactMap { type in
            let sessions = filteredSessions.filter { $0.workoutType == type }
            guard !sessions.isEmpty else { return nil }
            return (type, sessions.count, sessions.reduce(0) { $0 + $1.durationMinutes })
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Tab selector for race training goals
            if isRaceTraining || !(goal.personalRecords ?? []).isEmpty {
                Picker("Tab", selection: $selectedTab) {
                    ForEach(FitnessTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    switch selectedTab {
                    case .overview:
                        overviewContent
                    case .training:
                        trainingContent
                    case .records:
                        recordsContent
                    }
                }
                .padding(24)
            }
        }
        .background(Color.goalSecondaryBackground)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                if goal.fitnessConfig == nil {
                    Button {
                        showingSetupSheet = true
                    } label: {
                        Label("Configure", systemImage: "gearshape")
                    }
                }

                Button {
                    showingAddSession = true
                } label: {
                    Label("Add Workout", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSession) {
            AddTrainingSessionSheet(goal: goal) { session in
                modelContext.insert(session)
                session.goal = goal
                goal.updateProgress()
            }
        }
        .sheet(isPresented: $showingSetupSheet) {
            SetupFitnessGoalSheet(goal: goal) { config in
                modelContext.insert(config)
                config.goal = goal
                goal.fitnessConfig = config
            }
        }
        .sheet(isPresented: $showingAddPRSheet) {
            AddPersonalRecordSheet(goal: goal) { record in
                modelContext.insert(record)
                record.goal = goal
            }
        }
    }

    // MARK: - Overview Content

    @ViewBuilder
    private var overviewContent: some View {
        GoalProgressHeader(goal: goal)

        // Race Training Dashboard
        if let config = goal.fitnessConfig, isRaceTraining {
            RaceCountdownCard(config: config)

            if let targetPace = config.targetPaceSecondsPerKm {
                PaceComparisonCard(
                    targetPaceSecondsPerKm: targetPace,
                    currentPaceSecondsPerKm: goal.recentPaceSecondsPerKm,
                    recentPaces: Array(goal.sortedTrainingSessions.compactMap { $0.effectivePace }.prefix(10).reversed())
                )
            }

            TrainingPhaseTimeline(config: config)
        }

        filterBar
        statsOverview
        workoutBreakdownSection

        if !filteredSessions.isEmpty {
            activityChart
        }
    }

    // MARK: - Training Content

    @ViewBuilder
    private var trainingContent: some View {
        if let config = goal.fitnessConfig, isRaceTraining {
            WeeklyMileageChart(
                sessions: goal.sortedTrainingSessions,
                targetMileageKm: config.weeklyMileageTargetKm
            )

            LongRunProgressionCard(sessions: goal.sortedTrainingSessions.filter { $0.workoutType == .run })
        }

        sessionsListSection
    }

    // MARK: - Records Content

    @ViewBuilder
    private var recordsContent: some View {
        PersonalRecordsView(
            records: goal.personalRecords ?? [],
            onAddRecord: {
                showingAddPRSheet = true
            }
        )
    }

    private var filterBar: some View {
        HStack {
            Picker("Time Range", selection: $selectedTimeRange) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 300)

            Spacer()

            Menu {
                Button("All Types") {
                    selectedWorkoutType = nil
                }
                Divider()
                ForEach(WorkoutType.allCases) { type in
                    Button {
                        selectedWorkoutType = type
                    } label: {
                        Label(type.displayName, systemImage: type.icon)
                    }
                }
            } label: {
                HStack {
                    Image(systemName: selectedWorkoutType?.icon ?? "line.3.horizontal.decrease.circle")
                    Text(selectedWorkoutType?.displayName ?? "All Types")
                }
            }
        }
    }

    private var statsOverview: some View {
        HStack(spacing: 16) {
            StatCard(
                title: "Workouts",
                value: "\(filteredSessions.count)",
                icon: "flame.fill",
                color: .orange
            )

            StatCard(
                title: "Total Time",
                value: formatDuration(totalDuration),
                icon: "clock.fill",
                color: .blue
            )

            if totalDistance > 0 {
                StatCard(
                    title: "Distance",
                    value: String(format: "%.1f km", totalDistance),
                    icon: "figure.run",
                    color: .green
                )
            }

            StatCard(
                title: "This Week",
                value: "\(thisWeekCount)",
                icon: "calendar",
                color: .purple
            )
        }
    }

    private var thisWeekCount: Int {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .weekOfYear, value: -1, to: Date()) ?? Date()
        return goal.sortedTrainingSessions.filter { $0.date >= weekAgo }.count
    }

    private var workoutBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Workout Breakdown")
                .font(.headline)

            HStack(spacing: 12) {
                ForEach(workoutTypeBreakdown, id: \.type) { item in
                    WorkoutTypeCard(
                        type: item.type,
                        count: item.count,
                        duration: item.duration,
                        isSelected: selectedWorkoutType == item.type
                    ) {
                        if selectedWorkoutType == item.type {
                            selectedWorkoutType = nil
                        } else {
                            selectedWorkoutType = item.type
                        }
                    }
                }
            }
        }
    }

    private var activityChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activity Over Time")
                .font(.headline)

            Chart(filteredSessions) { session in
                BarMark(
                    x: .value("Date", session.date, unit: .day),
                    y: .value("Duration", session.durationMinutes)
                )
                .foregroundStyle(session.workoutType.color)
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.month().day())
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel {
                        if let mins = value.as(Int.self) {
                            Text("\(mins)m")
                        }
                    }
                }
            }
            .padding()
            .background(Color.goalCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var sessionsListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Workouts")
                    .font(.headline)

                Spacer()

                Text("\(filteredSessions.count) sessions")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if filteredSessions.isEmpty {
                ContentUnavailableView {
                    Label("No Workouts", systemImage: "figure.run")
                } description: {
                    Text("Add your first workout to start tracking")
                } actions: {
                    Button("Add Workout") {
                        showingAddSession = true
                    }
                }
                .frame(height: 200)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(filteredSessions.prefix(20)) { session in
                        TrainingSessionRow(session: session) {
                            deleteSession(session)
                        }
                    }
                }
            }
        }
    }

    private func deleteSession(_ session: TrainingSession) {
        modelContext.delete(session)
        goal.updateProgress()
    }

    private func formatDuration(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 {
            return "\(hours)h \(mins)m"
        }
        return "\(mins)m"
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .foregroundStyle(.secondary)
            }
            .font(.caption)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.goalCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct WorkoutTypeCard: View {
    let type: WorkoutType
    let count: Int
    let duration: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(.title2)
                    .foregroundStyle(type.color)

                Text(type.displayName)
                    .font(.caption)
                    .fontWeight(.medium)

                Text("\(count)")
                    .font(.title3)
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? type.color.opacity(0.15) : Color.goalCardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? type.color : Color.clear, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

struct TrainingSessionRow: View {
    let session: TrainingSession
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: session.workoutType.icon)
                .font(.title2)
                .foregroundStyle(session.workoutType.color)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(session.displayTitle)
                    .font(.system(.body, weight: .medium))

                HStack(spacing: 12) {
                    Text(session.date.shortFormatted)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let distance = session.formattedDistance {
                        Text(distance)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let effort = session.effortDescription {
                        Text(effort)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
            }

            Spacer()

            Text(session.formattedDuration)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            Menu {
                Button("Delete", role: .destructive, action: onDelete)
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color.goalCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Goal.self, configurations: config)

    let goal = Goal(title: "Complete Ironman", goalType: .fitness, targetValue: 100)
    container.mainContext.insert(goal)

    return FitnessGoalDetailView(goal: goal)
        .modelContainer(container)
        .frame(width: 800, height: 700)
}
