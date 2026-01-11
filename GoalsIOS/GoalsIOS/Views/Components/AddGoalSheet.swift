import SwiftUI
import SwiftData

struct AddGoalSheet: View {
    let goalType: GoalType

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var description = ""
    @State private var targetValue: Int

    init(goalType: GoalType) {
        self.goalType = goalType
        switch goalType {
        case .bookReading:
            _targetValue = State(initialValue: Constants.Defaults.booksTarget)
        case .fitness:
            _targetValue = State(initialValue: Constants.Defaults.fitnessSessionsTarget)
        case .programming:
            _targetValue = State(initialValue: Constants.Defaults.commitsTarget)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Goal Title", text: $title)
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section {
                    Stepper("Target: \(targetValue)", value: $targetValue, in: 1...10000)
                } header: {
                    Text("Target")
                } footer: {
                    Text(targetFooterText)
                }

                Section {
                    HStack {
                        Text("End Date")
                        Spacer()
                        Text("Dec 31, \(Goal.currentYear)")
                            .foregroundStyle(.secondary)
                    }
                } footer: {
                    Text("Goals are year-based and end on December 31st")
                }
            }
            .navigationTitle("\(Goal.currentYear) \(goalType.displayName) Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createGoal()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private var targetFooterText: String {
        switch goalType {
        case .bookReading:
            return "Number of books to read"
        case .fitness:
            return "Number of training sessions"
        case .programming:
            return "Number of commits"
        }
    }

    private func createGoal() {
        let goal = Goal(
            title: title.trimmingCharacters(in: .whitespaces),
            goalType: goalType,
            targetValue: targetValue
        )

        if !description.trimmingCharacters(in: .whitespaces).isEmpty {
            goal.goalDescription = description.trimmingCharacters(in: .whitespaces)
        }

        // Set end date to Dec 31 of current year
        goal.endDate = Goal.endOfCurrentYear

        modelContext.insert(goal)
        dismiss()
    }
}

#Preview {
    AddGoalSheet(goalType: .bookReading)
        .modelContainer(for: Goal.self, inMemory: true)
}
