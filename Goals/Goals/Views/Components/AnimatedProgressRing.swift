import SwiftUI

struct AnimatedProgressRing: View {
    let progress: Double
    let color: Color
    var lineWidth: CGFloat = 12
    var showPercentage: Bool = true
    var animate: Bool = true
    var gradient: LinearGradient?

    @State private var animatedProgress: Double = 0

    private var effectiveGradient: LinearGradient {
        gradient ?? LinearGradient(
            colors: [color, color.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)

            // Progress circle
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    effectiveGradient,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: color.opacity(0.3), radius: 4, x: 0, y: 2)

            // Percentage text
            if showPercentage {
                VStack(spacing: 2) {
                    Text("\(Int(animatedProgress * 100))")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                    Text("%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .onAppear {
            if animate {
                withAnimation(.spring(response: 1.0, dampingFraction: 0.8)) {
                    animatedProgress = progress
                }
            } else {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { _, newValue in
            if animate {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    animatedProgress = newValue
                }
            } else {
                animatedProgress = newValue
            }
        }
    }
}

// MARK: - Convenience Initializers

extension AnimatedProgressRing {
    init(progress: Double, goalType: GoalType, lineWidth: CGFloat = 12) {
        self.progress = progress
        self.color = Color.forGoalType(goalType)
        self.lineWidth = lineWidth
        self.showPercentage = true
        self.animate = true
        self.gradient = nil
    }
}

// MARK: - Mini Progress Ring (for lists)

struct MiniProgressRing: View {
    let progress: Double
    let color: Color
    var size: CGFloat = 32

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 3)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))

            Text("\(Int(progress * 100))")
                .font(.system(size: size * 0.3, weight: .semibold, design: .rounded))
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 40) {
        AnimatedProgressRing(progress: 0.75, color: .blue)
            .frame(width: 120, height: 120)

        AnimatedProgressRing(
            progress: 0.45,
            color: .orange,
            gradient: LinearGradient(
                colors: [.orange, .red],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .frame(width: 100, height: 100)

        HStack(spacing: 20) {
            MiniProgressRing(progress: 0.3, color: .blue)
            MiniProgressRing(progress: 0.6, color: .green)
            MiniProgressRing(progress: 0.9, color: .purple)
        }
    }
    .padding()
}
