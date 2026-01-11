import SwiftUI
import Charts

struct RevenueChart: View {
    let entries: [RevenueEntry]
    var showGross: Bool = false
    var monthsToShow: Int = 12

    private var chartData: [RevenueDataPoint] {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .month, value: -monthsToShow, to: Date())!

        // Group entries by month
        var monthlyTotals: [Date: (gross: Double, net: Double)] = [:]

        for entry in entries where entry.date >= startDate {
            let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: entry.date))!
            let existing = monthlyTotals[monthStart] ?? (gross: 0, net: 0)
            monthlyTotals[monthStart] = (
                gross: existing.gross + entry.grossRevenue,
                net: existing.net + entry.netRevenue
            )
        }

        // Create array with all months (including zeros)
        var result: [RevenueDataPoint] = []
        var currentMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: startDate))!

        while currentMonth <= Date() {
            let totals = monthlyTotals[currentMonth] ?? (gross: 0, net: 0)
            result.append(RevenueDataPoint(
                month: currentMonth,
                grossRevenue: totals.gross,
                netRevenue: totals.net,
                isCurrentMonth: calendar.isDate(currentMonth, equalTo: Date(), toGranularity: .month)
            ))
            currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth)!
        }

        return result
    }

    private var maxRevenue: Double {
        let maxValue = chartData.map { showGross ? $0.grossRevenue : $0.netRevenue }.max() ?? 0
        return max(maxValue * 1.1, 100)
    }

    private var totalRevenue: Double {
        chartData.reduce(0) { $0 + (showGross ? $1.grossRevenue : $1.netRevenue) }
    }

    private var averageMonthlyRevenue: Double {
        let nonZeroMonths = chartData.filter { $0.netRevenue > 0 }
        guard !nonZeroMonths.isEmpty else { return 0 }
        return nonZeroMonths.map { showGross ? $0.grossRevenue : $0.netRevenue }.reduce(0, +) / Double(nonZeroMonths.count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.title2)
                    .foregroundStyle(.green)
                Text("Revenue")
                    .font(.headline)
                Spacer()

                // Toggle gross/net
                Picker("Revenue Type", selection: .constant(showGross)) {
                    Text("Net").tag(false)
                    Text("Gross").tag(true)
                }
                .pickerStyle(.segmented)
                .frame(width: 120)
            }

            Chart {
                ForEach(chartData) { dataPoint in
                    BarMark(
                        x: .value("Month", dataPoint.month, unit: .month),
                        y: .value("Revenue", showGross ? dataPoint.grossRevenue : dataPoint.netRevenue)
                    )
                    .foregroundStyle(barGradient(for: dataPoint))
                    .cornerRadius(4)
                }
            }
            .chartYScale(domain: 0...maxRevenue)
            .chartXAxis {
                AxisMarks(values: .stride(by: .month, count: 2)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month(.abbreviated))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text(formatCurrency(amount, compact: true))
                                .font(.caption)
                        }
                    }
                }
            }
            .frame(height: 200)

            // Summary stats
            HStack(spacing: 24) {
                RevenueStatItem(
                    label: "Total",
                    value: formatCurrency(totalRevenue)
                )

                RevenueStatItem(
                    label: "Average/mo",
                    value: formatCurrency(averageMonthlyRevenue)
                )

                if let currentMonth = chartData.last {
                    RevenueStatItem(
                        label: "This Month",
                        value: formatCurrency(showGross ? currentMonth.grossRevenue : currentMonth.netRevenue)
                    )
                }

                if let lastMonth = chartData.dropLast().last,
                   let currentMonth = chartData.last {
                    let change = (showGross ? currentMonth.grossRevenue : currentMonth.netRevenue) -
                                 (showGross ? lastMonth.grossRevenue : lastMonth.netRevenue)
                    RevenueStatItem(
                        label: "vs Last Month",
                        value: formatCurrency(change, showSign: true),
                        color: change >= 0 ? .green : .red
                    )
                }
            }
        }
        .padding()
        .background(Color.goalCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func barGradient(for dataPoint: RevenueDataPoint) -> LinearGradient {
        if dataPoint.isCurrentMonth {
            return LinearGradient(
                colors: [.blue, .cyan],
                startPoint: .bottom,
                endPoint: .top
            )
        }
        return LinearGradient(
            colors: [.green.opacity(0.7), .green],
            startPoint: .bottom,
            endPoint: .top
        )
    }

    private func formatCurrency(_ amount: Double, compact: Bool = false, showSign: Bool = false) -> String {
        let sign = showSign && amount >= 0 ? "+" : ""
        if compact && abs(amount) >= 1000 {
            return "\(sign)$\(String(format: "%.1fk", amount / 1000))"
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        let formatted = formatter.string(from: NSNumber(value: abs(amount))) ?? "$0"
        return amount < 0 ? "-\(formatted)" : "\(sign)\(formatted)"
    }
}

// MARK: - Supporting Types

struct RevenueDataPoint: Identifiable {
    let id = UUID()
    let month: Date
    let grossRevenue: Double
    let netRevenue: Double
    let isCurrentMonth: Bool

    var monthLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: month)
    }
}

private struct RevenueStatItem: View {
    let label: String
    let value: String
    var color: Color = .primary

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Revenue Summary Card

struct RevenueSummaryCard: View {
    let projects: [AppProject]

    private var totalThisMonth: Double {
        projects.reduce(0) { $0 + $1.thisMonthRevenue }
    }

    private var totalLastMonth: Double {
        projects.reduce(0) { $0 + $1.lastMonthRevenue }
    }

    private var growthPercentage: Double? {
        guard totalLastMonth > 0 else { return nil }
        return ((totalThisMonth - totalLastMonth) / totalLastMonth) * 100
    }

    private var allTimeTotal: Double {
        projects.reduce(0) { $0 + $1.totalRevenue }
    }

    var body: some View {
        HStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("App Revenue")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(formatCurrency(totalThisMonth))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.green)

                Text("this month")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 12) {
                if let growth = growthPercentage {
                    HStack(spacing: 4) {
                        Image(systemName: growth >= 0 ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill")
                        Text(String(format: "%.0f%%", abs(growth)))
                    }
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(growth >= 0 ? .green : .red)
                }

                VStack(alignment: .trailing, spacing: 2) {
                    Text(formatCurrency(allTimeTotal))
                        .font(.headline)
                    Text("all time")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color.green.opacity(0.1), Color.goalCardBackground],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

// MARK: - Preview

#Preview {
    let entries: [RevenueEntry] = (0..<12).map { monthsAgo in
        RevenueEntry(
            date: Calendar.current.date(byAdding: .month, value: -monthsAgo, to: Date())!,
            period: .monthly,
            grossRevenue: Double.random(in: 800...2000),
            netRevenue: Double.random(in: 680...1700)
        )
    }

    let project1 = AppProject(name: "Goals App", platform: .iOS)
    project1.revenueEntries = Array(entries.prefix(6))

    let project2 = AppProject(name: "Habit Tracker", platform: .macOS)
    project2.revenueEntries = Array(entries.suffix(6))

    return VStack(spacing: 20) {
        RevenueSummaryCard(projects: [project1, project2])
        RevenueChart(entries: entries)
    }
    .padding()
    .frame(width: 600, height: 500)
}
