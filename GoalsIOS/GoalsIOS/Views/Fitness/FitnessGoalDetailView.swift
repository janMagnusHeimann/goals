import SwiftUI
import SwiftData

struct FitnessGoalDetailView: View {
    @Bindable var goal: Goal

    @Environment(\.modelContext) private var modelContext
    @State private var showingAddSession = false
    @State private var showingSetupSheet = false
    @State private var showingAddPR = false
    @State private var selectedTab: FitnessTab = .overview

    enum FitnessTab: String, CaseIterable {
        case overview = "Overview"
        case training = "Training"
        case records = "Records"
    }

    private var isRaceTraining: Bool {
        goal.fitnessConfig?.fitnessGoalType == .raceTraining
    }

    var body: some View {
        VStack(spacing: 0) {
            // Tab selector for enhanced goals
            if isRaceTraining || !(goal.personalRecords ?? []).isEmpty {
                Picker("Tab", selection: $selectedTab) {
                    ForEach(FitnessTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
            }

            List {
                switch selectedTab {
                case .overview:
                    overviewSections
                case .training:
                    trainingSections
                case .records:
                    recordsSections
                }
            }
        }
        .navigationTitle(goal.title)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Menu {
                    Button {
                        showingAddSession = true
                    } label: {
                        Label("Add Workout", systemImage: "figure.run")
                    }

                    Button {
                        showingAddPR = true
                    } label: {
                        Label("Add PR", systemImage: "trophy")
                    }

                    if goal.fitnessConfig == nil {
                        Button {
                            showingSetupSheet = true
                        } label: {
                            Label("Configure Goal", systemImage: "gearshape")
                        }
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSession) {
            AddTrainingSessionSheet(goal: goal)
        }
        .sheet(isPresented: $showingSetupSheet) {
            SetupFitnessGoalSheet(goal: goal) { config in
                modelContext.insert(config)
                config.goal = goal
                goal.fitnessConfig = config
            }
        }
        .sheet(isPresented: $showingAddPR) {
            AddPersonalRecordSheet(goal: goal) { record in
                modelContext.insert(record)
                record.goal = goal
            }
        }
        .onChange(of: goal.trainingSessions?.count) {
            goal.updateProgress()
        }
    }

    // MARK: - Overview Sections

    @ViewBuilder
    private var overviewSections: some View {
        // Progress Section
        Section {
            VStack(spacing: 16) {
                HStack {
                    ProgressRing(progress: goal.progress, color: .orange)
                        .frame(width: 80, height: 80)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(goal.currentValue) of \(goal.targetValue) sessions")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("\(goal.progressPercentage)% complete")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
            }
            .padding(.vertical, 8)
        }

        // Race Training Info
        if let config = goal.fitnessConfig, isRaceTraining {
            Section("Race") {
                if let raceName = config.raceName {
                    LabeledContent("Race", value: raceName)
                } else if let raceType = config.raceType {
                    LabeledContent("Race", value: raceType.displayName)
                }

                if let days = config.daysUntilRace {
                    LabeledContent("Days Until Race") {
                        Text("\(days)")
                            .fontWeight(.bold)
                            .foregroundStyle(.orange)
                    }
                }

                if let targetPace = config.targetPaceSecondsPerKm {
                    LabeledContent("Target Pace") {
                        Text(formatPace(targetPace))
                            .fontWeight(.medium)
                    }
                }

                if let currentPace = goal.recentPaceSecondsPerKm {
                    LabeledContent("Current Pace") {
                        Text(formatPace(currentPace))
                            .fontWeight(.medium)
                            .foregroundStyle(currentPace <= (config.targetPaceSecondsPerKm ?? Int.max) ? .green : .orange)
                    }
                }

                if let phase = config.currentPhase {
                    LabeledContent("Training Phase") {
                        PhaseBadge(phase: phase)
                    }
                }
            }
        }

        // Workout Summary
        Section("Workout Summary") {
            ForEach(WorkoutType.allCases) { type in
                let count = sessionsCount(for: type)
                if count > 0 {
                    HStack {
                        Label(type.displayName, systemImage: type.icon)
                            .foregroundStyle(type.color)
                        Spacer()
                        Text("\(count)")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Training Sections

    @ViewBuilder
    private var trainingSections: some View {
        // Weekly Mileage Summary
        if let config = goal.fitnessConfig, isRaceTraining {
            Section("Weekly Mileage") {
                let currentWeekMileage = goal.totalWeeklyMileage
                let target = config.weeklyMileageTargetKm ?? 50

                HStack {
                    VStack(alignment: .leading) {
                        Text(String(format: "%.1f km", currentWeekMileage))
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("this week")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing) {
                        Text(String(format: "%.0f km", target))
                            .font(.headline)
                        Text("target")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                ProgressView(value: min(currentWeekMileage / target, 1.0))
                    .tint(currentWeekMileage >= target ? .green : .blue)
            }
        }

        // Recent Sessions
        Section("Recent Sessions") {
            if goal.sortedTrainingSessions.isEmpty {
                Text("No sessions logged yet")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(goal.sortedTrainingSessions.prefix(15)) { session in
                    SessionRowView(session: session)
                }
                .onDelete(perform: deleteSessions)
            }
        }
    }

    // MARK: - Records Sections

    @ViewBuilder
    private var recordsSections: some View {
        let records = goal.personalRecords ?? []

        if records.isEmpty {
            Section {
                ContentUnavailableView {
                    Label("No Personal Records", systemImage: "trophy")
                } description: {
                    Text("Add your first PR to track your progress")
                } actions: {
                    Button("Add PR") {
                        showingAddPR = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        } else {
            ForEach(PRCategory.allCases) { category in
                let categoryRecords = records.filter { $0.category == category }
                if !categoryRecords.isEmpty {
                    Section(category.displayName) {
                        ForEach(categoryRecords.sorted { $0.achievedDate > $1.achievedDate }) { record in
                            PersonalRecordRowCompact(record: record)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func sessionsCount(for type: WorkoutType) -> Int {
        goal.sortedTrainingSessions.filter { $0.workoutType == type }.count
    }

    private func deleteSessions(at offsets: IndexSet) {
        let sessions = Array(goal.sortedTrainingSessions.prefix(15))
        for index in offsets {
            modelContext.delete(sessions[index])
        }
        goal.updateProgress()
    }

    private func formatPace(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d/km", minutes, secs)
    }
}

// MARK: - Session Row View

struct SessionRowView: View {
    let session: TrainingSession

    var body: some View {
        HStack {
            Image(systemName: session.workoutType.icon)
                .foregroundStyle(session.workoutType.color)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(session.displayTitle)
                    .font(.headline)

                HStack(spacing: 12) {
                    Text(session.date.shortFormatted)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let distance = session.formattedDistance {
                        Text(distance)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let pace = session.formattedPace {
                        Text(pace)
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }

                    if let intent = session.workoutIntent {
                        Text(intent.displayName)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(intent.color.opacity(0.2))
                            .clipShape(Capsule())
                    }
                }
            }

            Spacer()

            Text(session.formattedDuration)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Personal Record Row Compact

struct PersonalRecordRowCompact: View {
    let record: PersonalRecord

    var body: some View {
        HStack {
            Image(systemName: "trophy.fill")
                .foregroundStyle(.yellow)

            VStack(alignment: .leading, spacing: 2) {
                Text(record.exercise)
                    .font(.headline)

                Text(record.achievedDate, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(record.formattedValue)
                    .font(.headline)
                    .fontWeight(.bold)

                if let improvement = record.formattedImprovement {
                    HStack(spacing: 2) {
                        Image(systemName: record.isImprovement ? "arrow.up" : "arrow.down")
                            .font(.caption2)
                        Text(improvement)
                    }
                    .font(.caption)
                    .foregroundStyle(record.isImprovement ? .green : .red)
                }
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Goal.self, configurations: config)
    let goal = Goal(title: "Ironman Training", goalType: .fitness, targetValue: 100)
    container.mainContext.insert(goal)

    return NavigationStack {
        FitnessGoalDetailView(goal: goal)
    }
    .modelContainer(container)
}
