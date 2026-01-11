import SwiftUI

struct SetupFitnessGoalSheet: View {
    @Environment(\.dismiss) private var dismiss

    let goal: Goal
    let onSave: (FitnessGoalConfig) -> Void

    @State private var fitnessGoalType: FitnessGoalType = .consistencyGoal
    @State private var raceType: RaceType = .marathon
    @State private var raceName: String = ""
    @State private var raceDate: Date = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
    @State private var targetPaceMinutes: Int = 5
    @State private var targetPaceSeconds: Int = 30
    @State private var targetFinishHours: Int = 4
    @State private var targetFinishMinutes: Int = 0
    @State private var weeklyMileageTarget: String = "50"
    @State private var currentPhase: TrainingPhase = .base
    @State private var workoutsPerWeek: Int = 4

    private var targetPaceSecondsPerKm: Int {
        targetPaceMinutes * 60 + targetPaceSeconds
    }

    private var targetFinishTimeSeconds: Int {
        targetFinishHours * 3600 + targetFinishMinutes * 60
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Configure Fitness Goal")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Goal Type
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Goal Type")
                            .font(.headline)

                        Picker("Goal Type", selection: $fitnessGoalType) {
                            ForEach(FitnessGoalType.allCases) { type in
                                Label(type.displayName, systemImage: type.icon)
                                    .tag(type)
                            }
                        }
                        .pickerStyle(.segmented)

                        Text(fitnessGoalType.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    // Race Training Options
                    if fitnessGoalType == .raceTraining {
                        raceTrainingOptions
                    }

                    // Consistency Options
                    if fitnessGoalType == .consistencyGoal {
                        consistencyOptions
                    }

                    // Strength Options
                    if fitnessGoalType == .strengthGoal {
                        strengthOptions
                    }
                }
                .padding()
            }

            Divider()

            // Footer
            HStack {
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape)

                Button("Save Configuration") {
                    saveConfig()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return)
            }
            .padding()
        }
        .frame(width: 500, height: 600)
    }

    // MARK: - Race Training Options

    @ViewBuilder
    private var raceTrainingOptions: some View {
        // Race Type
        VStack(alignment: .leading, spacing: 8) {
            Text("Race Type")
                .font(.headline)

            Picker("Race Type", selection: $raceType) {
                ForEach(RaceType.allCases) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .pickerStyle(.segmented)

            Text("Distance: \(String(format: "%.2f", raceType.distanceKm)) km")
                .font(.caption)
                .foregroundStyle(.secondary)
        }

        // Race Name
        VStack(alignment: .leading, spacing: 8) {
            Text("Race Name (optional)")
                .font(.headline)
            TextField("e.g., Berlin Marathon 2026", text: $raceName)
                .textFieldStyle(.roundedBorder)
        }

        // Race Date
        VStack(alignment: .leading, spacing: 8) {
            Text("Race Date")
                .font(.headline)
            DatePicker("", selection: $raceDate, displayedComponents: .date)
                .labelsHidden()

            let daysUntil = Calendar.current.dateComponents([.day], from: Date(), to: raceDate).day ?? 0
            Text("\(daysUntil) days until race")
                .font(.caption)
                .foregroundStyle(.orange)
        }

        // Target Pace
        VStack(alignment: .leading, spacing: 8) {
            Text("Target Pace (per km)")
                .font(.headline)

            HStack {
                Picker("Minutes", selection: $targetPaceMinutes) {
                    ForEach(3..<10) { min in
                        Text("\(min)").tag(min)
                    }
                }
                .frame(width: 60)

                Text(":")

                Picker("Seconds", selection: $targetPaceSeconds) {
                    ForEach(0..<60) { sec in
                        Text(String(format: "%02d", sec)).tag(sec)
                    }
                }
                .frame(width: 60)

                Text("/km")
                    .foregroundStyle(.secondary)
            }

            Text("Estimated finish: \(formatTime(Int(raceType.distanceKm * Double(targetPaceSecondsPerKm))))")
                .font(.caption)
                .foregroundStyle(.green)
        }

        // Weekly Mileage Target
        VStack(alignment: .leading, spacing: 8) {
            Text("Weekly Mileage Target")
                .font(.headline)

            HStack {
                TextField("50", text: $weeklyMileageTarget)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
                Text("km per week")
                    .foregroundStyle(.secondary)
            }
        }

        // Current Phase
        VStack(alignment: .leading, spacing: 8) {
            Text("Current Training Phase")
                .font(.headline)

            Picker("Phase", selection: $currentPhase) {
                ForEach(TrainingPhase.allCases) { phase in
                    Text(phase.displayName).tag(phase)
                }
            }
            .pickerStyle(.segmented)

            Text(currentPhase.description)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Consistency Options

    @ViewBuilder
    private var consistencyOptions: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Workouts Per Week")
                .font(.headline)

            Picker("Workouts", selection: $workoutsPerWeek) {
                ForEach(1..<8) { count in
                    Text("\(count)").tag(count)
                }
            }
            .pickerStyle(.segmented)

            Text("Target: \(workoutsPerWeek) workouts every week")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Strength Options

    @ViewBuilder
    private var strengthOptions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Strength Training")
                .font(.headline)

            Text("Track your personal records and strength progression in the Records tab.")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundStyle(.yellow)
                Text("Add PRs after saving this configuration")
                    .font(.caption)
            }
            .padding()
            .background(Color.yellow.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    // MARK: - Helpers

    private func formatTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%d:%02d", minutes, secs)
    }

    private func saveConfig() {
        let config = FitnessGoalConfig(fitnessGoalType: fitnessGoalType)

        if fitnessGoalType == .raceTraining {
            config.raceType = raceType
            config.raceName = raceName.isEmpty ? nil : raceName
            config.raceDate = raceDate
            config.targetPaceSecondsPerKm = targetPaceSecondsPerKm
            config.targetFinishTimeSeconds = Int(raceType.distanceKm * Double(targetPaceSecondsPerKm))
            config.weeklyMileageTargetKm = Double(weeklyMileageTarget) ?? 50
            config.currentPhase = currentPhase
        } else if fitnessGoalType == .consistencyGoal {
            config.workoutsPerWeekTarget = workoutsPerWeek
        }

        onSave(config)
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    let goal = Goal(title: "Marathon 2026", goalType: .fitness, targetValue: 100)

    return SetupFitnessGoalSheet(goal: goal) { config in
        print("Saved config: \(config.fitnessGoalType)")
    }
}
