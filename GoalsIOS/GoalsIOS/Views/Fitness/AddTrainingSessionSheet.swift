import SwiftUI
import SwiftData

struct AddTrainingSessionSheet: View {
    let goal: Goal

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var workoutType: WorkoutType = .run
    @State private var date = Date()
    @State private var hours = 0
    @State private var minutes = 30
    @State private var distance = ""
    @State private var distanceUnit: DistanceUnit = .kilometers
    @State private var notes = ""
    @State private var perceivedEffort = 5

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Workout Type", selection: $workoutType) {
                        ForEach(WorkoutType.allCases) { type in
                            Label(type.displayName, systemImage: type.icon)
                                .tag(type)
                        }
                    }

                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }

                Section("Duration") {
                    HStack {
                        Picker("Hours", selection: $hours) {
                            ForEach(0..<24) { hour in
                                Text("\(hour)h").tag(hour)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 100)

                        Picker("Minutes", selection: $minutes) {
                            ForEach(0..<60) { minute in
                                Text("\(minute)m").tag(minute)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 100)
                    }
                    .frame(height: 120)
                }

                Section("Distance (optional)") {
                    HStack {
                        TextField("Distance", text: $distance)
                            .keyboardType(.decimalPad)

                        Picker("Unit", selection: $distanceUnit) {
                            ForEach(DistanceUnit.allCases, id: \.self) { unit in
                                Text(unit.displayName).tag(unit)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }

                Section("Effort Level") {
                    VStack {
                        Slider(value: Binding(
                            get: { Double(perceivedEffort) },
                            set: { perceivedEffort = Int($0) }
                        ), in: 1...10, step: 1)

                        HStack {
                            Text("Easy")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(perceivedEffort)/10")
                                .font(.headline)
                            Spacer()
                            Text("Maximum")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Notes (optional)") {
                    TextField("How did it go?", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Log Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveSession()
                    }
                    .disabled(hours == 0 && minutes == 0)
                }
            }
        }
    }

    private func saveSession() {
        let session = TrainingSession(
            workoutType: workoutType,
            date: date,
            durationMinutes: hours * 60 + minutes
        )

        if let distanceValue = Double(distance), distanceValue > 0 {
            session.distance = distanceValue
            session.distanceUnit = distanceUnit
        }

        if !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            session.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        session.perceivedEffort = perceivedEffort
        session.goal = goal

        modelContext.insert(session)
        goal.updateProgress()
        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Goal.self, configurations: config)
    let goal = Goal(title: "Ironman Training", goalType: .fitness, targetValue: 100)
    container.mainContext.insert(goal)

    return AddTrainingSessionSheet(goal: goal)
        .modelContainer(container)
}
