import SwiftUI

struct TrendIndicator: View {
    let currentValue: Double
    let previousValue: Double
    var format: TrendFormat = .percentage
    var positiveIsGood: Bool = true
    var size: TrendSize = .medium

    private var change: Double {
        currentValue - previousValue
    }

    private var percentageChange: Double {
        guard previousValue != 0 else { return 0 }
        return (change / abs(previousValue)) * 100
    }

    private var isPositive: Bool {
        change > 0
    }

    private var isNeutral: Bool {
        abs(change) < 0.001
    }

    private var trendColor: Color {
        if isNeutral { return .gray }
        let goodChange = positiveIsGood ? isPositive : !isPositive
        return goodChange ? .green : .red
    }

    private var arrowIcon: String {
        if isNeutral { return "minus" }
        return isPositive ? "arrow.up" : "arrow.down"
    }

    private var formattedChange: String {
        switch format {
        case .percentage:
            let sign = isPositive ? "+" : ""
            return String(format: "%@%.1f%%", sign, percentageChange)
        case .absolute:
            let sign = isPositive ? "+" : ""
            return String(format: "%@%.1f", sign, change)
        case .integer:
            let sign = isPositive ? "+" : ""
            return String(format: "%@%.0f", sign, change)
        case .currency:
            let sign = isPositive ? "+" : ""
            return String(format: "%@$%.2f", sign, change)
        }
    }

    var body: some View {
        HStack(spacing: size.spacing) {
            Image(systemName: arrowIcon)
                .font(.system(size: size.iconSize, weight: .bold))

            Text(formattedChange)
                .font(.system(size: size.fontSize, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(trendColor)
        .padding(.horizontal, size.padding)
        .padding(.vertical, size.padding * 0.5)
        .background(trendColor.opacity(0.1))
        .clipShape(Capsule())
    }

    enum TrendFormat {
        case percentage
        case absolute
        case integer
        case currency
    }

    enum TrendSize {
        case small, medium, large

        var iconSize: CGFloat {
            switch self {
            case .small: return 8
            case .medium: return 10
            case .large: return 14
            }
        }

        var fontSize: CGFloat {
            switch self {
            case .small: return 10
            case .medium: return 12
            case .large: return 16
            }
        }

        var spacing: CGFloat {
            switch self {
            case .small: return 2
            case .medium: return 3
            case .large: return 4
            }
        }

        var padding: CGFloat {
            switch self {
            case .small: return 4
            case .medium: return 6
            case .large: return 8
            }
        }
    }
}

// MARK: - Trend Comparison Card

struct TrendComparisonCard: View {
    let title: String
    let currentValue: String
    let previousValue: Double
    let currentNumericValue: Double
    var subtitle: String?
    var format: TrendIndicator.TrendFormat = .percentage
    var icon: String?
    var iconColor: Color = .blue

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundStyle(iconColor)
                }
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            HStack(alignment: .bottom, spacing: 8) {
                Text(currentValue)
                    .font(.system(size: 28, weight: .bold, design: .rounded))

                TrendIndicator(
                    currentValue: currentNumericValue,
                    previousValue: previousValue,
                    format: format,
                    size: .small
                )
            }

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color.goalCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        HStack(spacing: 12) {
            TrendIndicator(currentValue: 150, previousValue: 100, format: .percentage, size: .small)
            TrendIndicator(currentValue: 80, previousValue: 100, format: .percentage, size: .small)
            TrendIndicator(currentValue: 100, previousValue: 100, format: .percentage, size: .small)
        }

        HStack(spacing: 12) {
            TrendIndicator(currentValue: 1250, previousValue: 1000, format: .currency, size: .medium)
            TrendIndicator(currentValue: 45, previousValue: 50, format: .integer, positiveIsGood: false, size: .medium)
        }

        TrendIndicator(currentValue: 5.5, previousValue: 4.2, format: .absolute, size: .large)

        TrendComparisonCard(
            title: "Revenue",
            currentValue: "$1,250",
            previousValue: 1000,
            currentNumericValue: 1250,
            subtitle: "vs last month",
            format: .percentage,
            icon: "dollarsign.circle.fill",
            iconColor: .green
        )
        .frame(width: 200)
    }
    .padding()
}
