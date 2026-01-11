import SwiftUI
import Charts

struct WeeklyMileageChart: View {
    let sessions: [TrainingSession]
    var targetMileageKm: Double?
    var weeksToShow: Int = 12

    private var weeklyData: [WeeklyMileage] {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .weekOfYear, value: -weeksToShow, to: Date())!

        // Group sessions by week
        var weeklyTotals: [Date: Double] = [:]

        for session in sessions where session.date >= startDate {
            guard let distanceKm = session.distanceKm else { continue }

            let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: session.date))!
            weeklyTotals[weekStart, default: 0] += distanceKm
        }

        // Create array with all weeks (including zeros)
        var result: [WeeklyMileage] = []
        var currentWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: startDate))!

        while currentWeek <= Date() {
            let distance = weeklyTotals[currentWeek] ?? 0
            result.append(WeeklyMileage(
                weekStart: currentWeek,
                distanceKm: distance,
                isCurrentWeek: calendar.isDate(currentWeek, equalTo: Date(), toGranularity: .weekOfYear)
            ))
            currentWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: currentWeek)!
        }

        return result
    }

    private var maxDistance: Double {
        max(weeklyData.map { $0.distanceKm }.max() ?? 0, targetMileageKm ?? 0) * 1.1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.title2)
                    .foregroundStyle(.green)
                Text("Weekly Mileage")
                    .font(.headline)
                Spacer()

                // Total this week
                if let currentWeek = weeklyData.last {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(String(format: "%.1f km", currentWeek.distanceKm))
                            .font(.title3)
                            .fontWeight(.bold)
                        Text("this week")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Chart {
                // Target line
                if let target = targetMileageKm {
                    RuleMark(y: .value("Target", target))
                        .foregroundStyle(.orange.opacity(0.7))
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                        .annotation(position: .trailing, alignment: .leading) {
                            Text("Target")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                        }
                }

                // Weekly bars
                ForEach(weeklyData) { week in
                    BarMark(
                        x: .value("Week", week.weekStart, unit: .weekOfYear),
                        y: .value("Distance", week.distanceKm)
                    )
                    .foregroundStyle(barColor(for: week))
                    .cornerRadius(4)
                }
            }
            .chartYScale(domain: 0...maxDistance)
            .chartXAxis {
                AxisMarks(values: .stride(by: .weekOfYear, count: 2)) { value in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let km = value.as(Double.self) {
                            Text("\(Int(km)) km")
                                .font(.caption)
                        }
                    }
                }
            }
            .frame(height: 200)

            // Summary stats
            HStack(spacing: 24) {
                StatItem(
                    label: "Average",
                    value: String(format: "%.1f km", averageWeeklyMileage)
                )

                if let target = targetMileageKm {
                    StatItem(
                        label: "Target",
                        value: String(format: "%.0f km", target)
                    )
                }

                StatItem(
                    label: "Peak",
                    value: String(format: "%.1f km", peakWeeklyMileage)
                )

                StatItem(
                    label: "Total",
                    value: String(format: "%.0f km", totalMileage)
                )
            }
        }
        .padding()
        .background(Color.goalCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func barColor(for week: WeeklyMileage) -> Color {
        if week.isCurrentWeek {
            return .blue
        }
        if let target = targetMileageKm {
            return week.distanceKm >= target ? .green : .green.opacity(0.6)
        }
        return .green.opacity(0.8)
    }

    private var averageWeeklyMileage: Double {
        let nonZeroWeeks = weeklyData.filter { $0.distanceKm > 0 }
        guard !nonZeroWeeks.isEmpty else { return 0 }
        return nonZeroWeeks.map { $0.distanceKm }.reduce(0, +) / Double(nonZeroWeeks.count)
    }

    private var peakWeeklyMileage: Double {
        weeklyData.map { $0.distanceKm }.max() ?? 0
    }

    private var totalMileage: Double {
        weeklyData.map { $0.distanceKm }.reduce(0, +)
    }
}

// MARK: - Supporting Types

struct WeeklyMileage: Identifiable {
    let id = UUID()
    let weekStart: Date
    let distanceKm: Double
    let isCurrentWeek: Bool

    var weekLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: weekStart)
    }
}

private struct StatItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Preview

#Preview {
    let sessions: [TrainingSession] = (0..<50).map { i in
        let session = TrainingSession(
            workoutType: .run,
            date: Calendar.current.date(byAdding: .day, value: -i * 2, to: Date())!,
            durationMinutes: Int.random(in: 30...90)
        )
        session.distance = Double.random(in: 5...20)
        session.distanceUnit = .kilometers
        return session
    }

    return WeeklyMileageChart(
        sessions: sessions,
        targetMileageKm: 50
    )
    .padding()
    .frame(width: 600, height: 400)
}
