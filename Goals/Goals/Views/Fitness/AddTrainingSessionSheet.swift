import SwiftUI

struct AddTrainingSessionSheet: View {
    @Environment(\.dismiss) private var dismiss
    let goal: Goal
    let onAdd: (TrainingSession) -> Void

    @State private var workoutType: WorkoutType = .run
    @State private var date = Date()
    @State private var hours = 0
    @State private var minutes = 30
    @State private var distance = ""
    @State private var distanceUnit: DistanceUnit = .kilometers
    @State private var heartRateAvg = ""
    @State private var heartRateMax = ""
    @State private var perceivedEffort = 5
    @State private var notes = ""
    @State private var title = ""

    private var totalMinutes: Int {
        hours * 60 + minutes
    }

    private var isValid: Bool {
        totalMinutes > 0
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    workoutTypeSection
                    dateTimeSection
                    distanceSection
                    heartRateSection
                    effortSection
                    notesSection
                }
                .padding(24)
            }

            Divider()

            footer
        }
        .frame(width: 500, height: 650)
    }

    private var header: some View {
        HStack {
            Text("Log Workout")
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
        .padding(20)
    }

    private var workoutTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Workout Type")
                .font(.headline)

            HStack(spacing: 8) {
                ForEach(WorkoutType.allCases) { type in
                    Button {
                        workoutType = type
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: type.icon)
                                .font(.title2)
                            Text(type.displayName)
                                .font(.caption2)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(workoutType == type ? type.color.opacity(0.2) : Color.goalCardBackground)
                        .foregroundStyle(workoutType == type ? type.color : .secondary)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(workoutType == type ? type.color : Color.goalBorder, lineWidth: workoutType == type ? 2 : 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var dateTimeSection: some View {
        HStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Date")
                    .font(.headline)

                DatePicker("", selection: $date, displayedComponents: .date)
                    .labelsHidden()
                    .datePickerStyle(.field)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Duration")
                    .font(.headline)

                HStack(spacing: 8) {
                    Picker("Hours", selection: $hours) {
                        ForEach(0..<13) { h in
                            Text("\(h)h").tag(h)
                        }
                    }
                    .frame(width: 70)

                    Picker("Minutes", selection: $minutes) {
                        ForEach(0..<60) { m in
                            Text("\(m)m").tag(m)
                        }
                    }
                    .frame(width: 70)
                }
            }
        }
    }

    private var distanceSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Distance (optional)")
                .font(.headline)

            HStack(spacing: 8) {
                TextField("0.0", text: $distance)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)

                Picker("Unit", selection: $distanceUnit) {
                    ForEach(DistanceUnit.allCases, id: \.self) { unit in
                        Text(unit.rawValue).tag(unit)
                    }
                }
                .frame(width: 80)
            }
        }
    }

    private var heartRateSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Heart Rate (optional)")
                .font(.headline)

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Average")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("bpm", text: $heartRateAvg)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Max")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("bpm", text: $heartRateMax)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                }
            }
        }
    }

    private var effortSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Perceived Effort")
                    .font(.headline)

                Spacer()

                Text(effortLabel)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 4) {
                ForEach(1...10, id: \.self) { level in
                    Button {
                        perceivedEffort = level
                    } label: {
                        Text("\(level)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .frame(width: 32, height: 32)
                            .background(effortColor(for: level).opacity(perceivedEffort >= level ? 1 : 0.2))
                            .foregroundStyle(perceivedEffort >= level ? .white : .secondary)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var effortLabel: String {
        switch perceivedEffort {
        case 1...3: return "Easy"
        case 4...6: return "Moderate"
        case 7...8: return "Hard"
        case 9...10: return "Maximum"
        default: return ""
        }
    }

    private func effortColor(for level: Int) -> Color {
        switch level {
        case 1...3: return .green
        case 4...6: return .yellow
        case 7...8: return .orange
        case 9...10: return .red
        default: return .gray
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes (optional)")
                .font(.headline)

            TextField("How did it go?", text: $notes, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(2...4)
        }
    }

    private var footer: some View {
        HStack {
            Spacer()

            Button("Cancel") {
                dismiss()
            }
            .keyboardShortcut(.escape)

            Button("Log Workout") {
                addSession()
            }
            .buttonStyle(.borderedProminent)
            .disabled(!isValid)
            .keyboardShortcut(.return)
        }
        .padding(20)
    }

    private func addSession() {
        let session = TrainingSession(
            workoutType: workoutType,
            date: date,
            durationMinutes: totalMinutes
        )

        if let dist = Double(distance), dist > 0 {
            session.distance = dist
            session.distanceUnit = distanceUnit
        }

        if let avgHR = Int(heartRateAvg) {
            session.heartRateAvg = avgHR
        }

        if let maxHR = Int(heartRateMax) {
            session.heartRateMax = maxHR
        }

        session.perceivedEffort = perceivedEffort
        session.notes = notes.isEmpty ? nil : notes
        session.title = title.isEmpty ? nil : title

        onAdd(session)
        dismiss()
    }
}

#Preview {
    AddTrainingSessionSheet(goal: Goal(title: "Test", goalType: .fitness, targetValue: 100)) { _ in }
}
