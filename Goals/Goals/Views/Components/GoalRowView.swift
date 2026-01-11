import SwiftUI

struct GoalRowView: View {
    @Bindable var goal: Goal

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(goal.title)
                    .font(.system(.body, weight: .medium))
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text("\(goal.currentValue)/\(goal.targetValue)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("•")
                        .font(.caption)
                        .foregroundStyle(.tertiary)

                    Text("\(goal.progressPercentage)%")
                        .font(.caption)
                        .foregroundStyle(progressColor)
                }
            }

            Spacer()

            CircularProgressView(
                progress: goal.progress,
                color: Color.forGoalType(goal.goalType),
                lineWidth: 3
            )
            .frame(width: 28, height: 28)
        }
        .padding(.vertical, 4)
    }

    private var progressColor: Color {
        if goal.progress >= 1.0 {
            return .green
        } else if goal.progress >= 0.5 {
            return .orange
        } else {
            return .secondary
        }
    }
}

struct CircularProgressView: View {
    let progress: Double
    let color: Color
    let lineWidth: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: progress)

            if progress >= 1.0 {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(color)
            }
        }
    }
}

#Preview {
    VStack {
        GoalRowView(goal: Goal(title: "Read 100 Books", goalType: .bookReading, targetValue: 100))
        GoalRowView(goal: Goal(title: "Complete Ironman", goalType: .fitness, targetValue: 365))
        GoalRowView(goal: Goal(title: "1000 Commits", goalType: .programming, targetValue: 1000))
    }
    .padding()
    .frame(width: 260)
}
