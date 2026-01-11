import SwiftUI

struct GoalCard: View {
    let goal: Goal

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: goal.goalType.icon)
                    .font(.title2)
                    .foregroundStyle(Color.forGoalType(goal.goalType))

                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.title)
                        .font(.headline)
                        .lineLimit(1)

                    Text("\(goal.currentValue) / \(goal.targetValue)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("\(goal.progressPercentage)%")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.forGoalType(goal.goalType))
            }

            ProgressView(value: goal.progress)
                .tint(Color.forGoalType(goal.goalType))
        }
        .padding()
        .background(Color.goalCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    let goal = Goal(title: "Read 12 Books", goalType: .bookReading, targetValue: 12)
    goal.currentValue = 5

    return GoalCard(goal: goal)
        .padding()
}
