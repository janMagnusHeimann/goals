import SwiftUI

struct ProgressBarView: View {
    let progress: Double
    let color: Color
    var height: CGFloat = 8
    var showLabel: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(color.opacity(0.2))
                        .frame(height: height)

                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(color)
                        .frame(width: max(0, geometry.size.width * progress), height: height)
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: height)

            if showLabel {
                HStack {
                    Text("\(Int(progress * 100))% complete")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    if progress >= 1.0 {
                        Label("Goal Achieved!", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
            }
        }
    }
}

struct GoalProgressHeader: View {
    let goal: Goal

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.title)
                        .font(.title)
                        .fontWeight(.bold)

                    if let description = goal.goalDescription {
                        Text(description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(goal.currentValue)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.forGoalType(goal.goalType))

                    Text("of \(goal.targetValue)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            ProgressBarView(
                progress: goal.progress,
                color: Color.forGoalType(goal.goalType),
                height: 10
            )

            HStack {
                if let endDate = goal.endDate {
                    Label(endDate.fullFormatted, systemImage: "calendar")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("Started \(goal.startDate.relativeFormatted)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(20)
        .background(Color.goalCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    VStack(spacing: 20) {
        ProgressBarView(progress: 0.65, color: .blue)
        ProgressBarView(progress: 1.0, color: .green)
        ProgressBarView(progress: 0.25, color: .orange, height: 12)

        let goal = Goal(title: "Read 100 Books", goalType: .bookReading, targetValue: 100)
        GoalProgressHeader(goal: goal)
    }
    .padding()
}
