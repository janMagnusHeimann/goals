import SwiftUI

struct PaceComparisonCard: View {
    let targetPaceSecondsPerKm: Int
    let currentPaceSecondsPerKm: Int?
    var showTrend: Bool = true
    var recentPaces: [Int] = []

    private var paceDifference: Int? {
        guard let current = currentPaceSecondsPerKm else { return nil }
        return current - targetPaceSecondsPerKm
    }

    private var isFasterThanTarget: Bool {
        guard let diff = paceDifference else { return false }
        return diff < 0
    }

    private var statusColor: Color {
        guard let diff = paceDifference else { return .gray }
        if abs(diff) <= 10 { return .green } // Within 10 seconds
        return isFasterThanTarget ? .green : .orange
    }

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Image(systemName: "speedometer")
                    .font(.title2)
                    .foregroundStyle(.orange)
                Text("Pace Comparison")
                    .font(.headline)
                Spacer()

                if let diff = paceDifference {
                    paceStatusBadge(difference: diff)
                }
            }

            // Pace Display
            HStack(spacing: 32) {
                // Target Pace
                VStack(spacing: 8) {
                    Text("Target")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    Text(formatPace(targetPaceSecondsPerKm))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    Text("/km")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                // Divider with arrow
                VStack(spacing: 4) {
                    Image(systemName: isFasterThanTarget ? "arrow.left" : "arrow.right")
                        .font(.title2)
                        .foregroundStyle(statusColor)

                    if let diff = paceDifference {
                        Text(formatDifference(diff))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(statusColor)
                    }
                }

                // Current Pace
                VStack(spacing: 8) {
                    Text("Current")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    if let current = currentPaceSecondsPerKm {
                        Text(formatPace(current))
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(statusColor)
                    } else {
                        Text("--:--")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)
                    }

                    Text("/km")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }

            // Pace Trend (if data available)
            if showTrend && !recentPaces.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent Trend")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    PaceTrendChart(
                        paces: recentPaces,
                        targetPace: targetPaceSecondsPerKm
                    )
                    .frame(height: 60)
                }
            }
        }
        .padding()
        .background(Color.goalCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func formatPace(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }

    private func formatDifference(_ diff: Int) -> String {
        let absDiff = abs(diff)
        let minutes = absDiff / 60
        let seconds = absDiff % 60

        let prefix = diff < 0 ? "" : "+"
        if minutes > 0 {
            return String(format: "%@%d:%02d", prefix, minutes, seconds)
        }
        return String(format: "%@%ds", prefix, seconds)
    }

    @ViewBuilder
    private func paceStatusBadge(difference: Int) -> some View {
        let isFaster = difference < 0
        let absDiff = abs(difference)

        HStack(spacing: 4) {
            Image(systemName: isFaster ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
            Text(isFaster ? "On Track" : "\(absDiff)s to go")
        }
        .font(.caption)
        .fontWeight(.medium)
        .foregroundStyle(statusColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(statusColor.opacity(0.15))
        .clipShape(Capsule())
    }
}

// MARK: - Pace Trend Chart

struct PaceTrendChart: View {
    let paces: [Int]
    let targetPace: Int

    var body: some View {
        GeometryReader { geometry in
            let minPace = min(paces.min() ?? targetPace, targetPace) - 30
            let maxPace = max(paces.max() ?? targetPace, targetPace) + 30
            let range = Double(maxPace - minPace)

            ZStack {
                // Target line
                let targetY = geometry.size.height * (1 - Double(targetPace - minPace) / range)
                Path { path in
                    path.move(to: CGPoint(x: 0, y: targetY))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: targetY))
                }
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [5, 5]))
                .foregroundStyle(.orange.opacity(0.5))

                // Pace line
                if paces.count > 1 {
                    Path { path in
                        for (index, pace) in paces.enumerated() {
                            let x = geometry.size.width * Double(index) / Double(paces.count - 1)
                            let y = geometry.size.height * (1 - Double(pace - minPace) / range)

                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(Color.green, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

                    // Points
                    ForEach(Array(paces.enumerated()), id: \.offset) { index, pace in
                        let x = geometry.size.width * Double(index) / Double(paces.count - 1)
                        let y = geometry.size.height * (1 - Double(pace - minPace) / range)

                        Circle()
                            .fill(pace <= targetPace ? Color.green : Color.orange)
                            .frame(width: 6, height: 6)
                            .position(x: x, y: y)
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        PaceComparisonCard(
            targetPaceSecondsPerKm: 330, // 5:30/km
            currentPaceSecondsPerKm: 345, // 5:45/km
            recentPaces: [360, 355, 350, 348, 345, 342]
        )

        PaceComparisonCard(
            targetPaceSecondsPerKm: 330,
            currentPaceSecondsPerKm: 320, // Faster than target
            recentPaces: [340, 335, 328, 325, 322, 320]
        )

        PaceComparisonCard(
            targetPaceSecondsPerKm: 330,
            currentPaceSecondsPerKm: nil
        )
    }
    .padding()
    .frame(width: 400)
}
