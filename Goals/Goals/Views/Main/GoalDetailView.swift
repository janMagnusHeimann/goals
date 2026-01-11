import SwiftUI

struct GoalDetailView: View {
    @Bindable var goal: Goal

    var body: some View {
        Group {
            switch goal.goalType {
            case .bookReading:
                BookGoalDetailView(goal: goal)
            case .fitness:
                FitnessGoalDetailView(goal: goal)
            case .programming:
                ProgrammingGoalDetailView(goal: goal)
            }
        }
        .id(goal.id)
    }
}

#Preview {
    GoalDetailView(goal: Goal(title: "Read 100 Books", goalType: .bookReading, targetValue: 100))
        .modelContainer(for: Goal.self, inMemory: true)
}
