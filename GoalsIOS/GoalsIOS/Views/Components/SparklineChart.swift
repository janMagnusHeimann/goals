import SwiftUI
import Charts

struct SparklineChart: View {
    let data: [Double]
    var color: Color = .blue
    var showArea: Bool = true
    var height: CGFloat = 40

    private var chartData: [(index: Int, value: Double)] {
        data.enumerated().map { (index: $0.offset, value: $0.element) }
    }

    private var minValue: Double {
        (data.min() ?? 0) * 0.9
    }

    private var maxValue: Double {
        (data.max() ?? 1) * 1.1
    }

    private var trend: TrendDirection {
        guard data.count >= 2 else { return .neutral }
        let firstHalf = data.prefix(data.count / 2).reduce(0, +) / Double(max(1, data.count / 2))
        let secondHalf = data.suffix(data.count / 2).reduce(0, +) / Double(max(1, data.count / 2))
        if secondHalf > firstHalf * 1.05 { return .up }
        if secondHalf < firstHalf * 0.95 { return .down }
        return .neutral
    }

    var body: some View {
        Chart(chartData, id: \.index) { item in
            if showArea {
                AreaMark(
                    x: .value("Index", item.index),
                    y: .value("Value", item.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [color.opacity(0.3), color.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }

            LineMark(
                x: .value("Index", item.index),
                y: .value("Value", item.value)
            )
            .foregroundStyle(color)
            .interpolationMethod(.catmullRom)
            .lineStyle(StrokeStyle(lineWidth: 2))
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartYScale(domain: minValue...maxValue)
        .frame(height: height)
    }

    enum TrendDirection {
        case up, down, neutral
    }
}

// MARK: - Sparkline with Label

struct LabeledSparkline: View {
    let title: String
    let value: String
    let data: [Double]
    var color: Color = .blue
    var trendValue: Double?
    var previousValue: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(alignment: .bottom, spacing: 8) {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))

                if let current = trendValue, let previous = previousValue {
                    TrendIndicator(
                        currentValue: current,
                        previousValue: previous,
                        format: .percentage,
                        size: .small
                    )
                }

                Spacer()

                SparklineChart(data: data, color: color, height: 30)
                    .frame(width: 60)
            }
        }
        .padding()
        .background(Color.goalCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Bar Sparkline

struct BarSparkline: View {
    let data: [Double]
    var color: Color = .blue
    var highlightLast: Bool = true
    var height: CGFloat = 40

    private var chartData: [(index: Int, value: Double)] {
        data.enumerated().map { (index: $0.offset, value: $0.element) }
    }

    var body: some View {
        Chart(chartData, id: \.index) { item in
            BarMark(
                x: .value("Index", item.index),
                y: .value("Value", item.value)
            )
            .foregroundStyle(
                highlightLast && item.index == data.count - 1
                    ? color
                    : color.opacity(0.5)
            )
            .cornerRadius(2)
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .frame(height: height)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        SparklineChart(
            data: [10, 15, 12, 18, 22, 20, 25, 28, 24, 30],
            color: .blue
        )
        .frame(width: 100, height: 40)

        SparklineChart(
            data: [30, 25, 28, 22, 18, 20, 15, 12, 10, 8],
            color: .red,
            showArea: false
        )
        .frame(width: 100, height: 40)

        LabeledSparkline(
            title: "Stars",
            value: "1,234",
            data: [100, 150, 180, 200, 280, 350, 420, 500, 650, 800, 950, 1234],
            color: .yellow,
            trendValue: 1234,
            previousValue: 950
        )
        .frame(width: 200)

        BarSparkline(
            data: [5, 8, 3, 12, 7, 9, 15, 10, 8, 12],
            color: .green
        )
        .frame(width: 100, height: 40)
    }
    .padding()
}
