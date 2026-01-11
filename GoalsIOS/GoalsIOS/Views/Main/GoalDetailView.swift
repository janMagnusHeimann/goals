import SwiftUI
import SwiftData

struct GoalDetailView: View {
    let goal: Goal

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
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Goal.self, configurations: config)
    let goal = Goal(title: "Read 12 Books", goalType: .bookReading, targetValue: 12)
    container.mainContext.insert(goal)

    return NavigationStack {
        GoalDetailView(goal: goal)
    }
    .modelContainer(container)
}
