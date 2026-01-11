import SwiftUI

struct NewGoalSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var description = ""
    @State private var goalType: GoalType = .bookReading
    @State private var targetValue = ""
    @State private var isGeneratingStructure = false

    let onCreate: (Goal) -> Void

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        Int(targetValue) ?? 0 > 0
    }

    private var defaultTarget: Int {
        switch goalType {
        case .bookReading: return Constants.Defaults.booksTarget
        case .fitness: return Constants.Defaults.fitnessSessionsTarget
        case .programming: return Constants.Defaults.commitsTarget
        }
    }

    private var targetLabel: String {
        switch goalType {
        case .bookReading: return "Books to Read"
        case .fitness: return "Training Sessions"
        case .programming: return "Target Commits"
        }
    }

    private var placeholderTitle: String {
        switch goalType {
        case .bookReading: return "Read 100 Books in \(Goal.currentYear)"
        case .fitness: return "Complete Ironman Training \(Goal.currentYear)"
        case .programming: return "Contribute to Open Source \(Goal.currentYear)"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    goalTypeSection
                    titleSection
                    targetSection
                    dateSection
                }
                .padding(24)
            }

            Divider()

            footer
        }
        .frame(width: 500, height: 520)
        .onAppear {
            targetValue = String(defaultTarget)
        }
        .onChange(of: goalType) { _, _ in
            targetValue = String(defaultTarget)
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("New \(Goal.currentYear) Goal")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("\(Goal.daysRemainingInYear) days remaining this year")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

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

    private var goalTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Goal Type")
                .font(.headline)

            HStack(spacing: 12) {
                ForEach(GoalType.allCases) { type in
                    GoalTypeCard(
                        type: type,
                        isSelected: goalType == type
                    ) {
                        goalType = type
                    }
                }
            }
        }
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Title")
                .font(.headline)

            TextField(placeholderTitle, text: $title)
                .textFieldStyle(.roundedBorder)

            TextField("Description (optional)", text: $description, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(2...4)
        }
    }

    private var targetSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(targetLabel)
                .font(.headline)

            HStack {
                TextField("Target", text: $targetValue)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)

                Stepper("", value: Binding(
                    get: { Int(targetValue) ?? 0 },
                    set: { targetValue = String($0) }
                ), in: 1...10000)
                .labelsHidden()
            }
        }
    }

    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("End Date")
                .font(.headline)

            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(.secondary)
                Text("December 31, \(Goal.currentYear)")
                    .foregroundStyle(.primary)
                Spacer()
            }
            .padding(12)
            .background(Color.goalCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.goalBorder, lineWidth: 1)
            )

            Text("Goals are year-based and end on December 31st")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var footer: some View {
        HStack {
            Spacer()

            Button("Cancel") {
                dismiss()
            }
            .keyboardShortcut(.escape)

            Button("Create Goal") {
                createGoal()
            }
            .buttonStyle(.borderedProminent)
            .disabled(!isValid)
            .keyboardShortcut(.return)
        }
        .padding(20)
    }

    private func createGoal() {
        let goal = Goal(
            title: title.trimmingCharacters(in: .whitespaces),
            goalType: goalType,
            targetValue: Int(targetValue) ?? defaultTarget
        )
        goal.goalDescription = description.isEmpty ? nil : description
        goal.endDate = Goal.endOfCurrentYear

        onCreate(goal)
        dismiss()
    }
}

struct GoalTypeCard: View {
    let type: GoalType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(.title)
                    .foregroundStyle(isSelected ? Color.forGoalType(type) : .secondary)

                Text(type.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSelected ? Color.forGoalType(type).opacity(0.1) : Color.goalCardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.forGoalType(type) : Color.goalBorder, lineWidth: isSelected ? 2 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NewGoalSheet { _ in }
}
