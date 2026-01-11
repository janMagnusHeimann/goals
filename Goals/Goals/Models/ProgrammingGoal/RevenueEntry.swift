import Foundation
import SwiftData

@Model
final class RevenueEntry {
    var id: UUID = UUID()
    var date: Date = Date()
    var period: RevenuePeriod = RevenuePeriod.monthly
    var grossRevenue: Double = 0
    var netRevenue: Double = 0
    var currency: String = "USD"
    var downloads: Int?
    var proceeds: Double?
    var refunds: Double?
    var inAppPurchases: Double?
    var subscriptions: Double?
    var notes: String?
    var createdAt: Date = Date()

    var project: AppProject?

    init(
        date: Date = Date(),
        period: RevenuePeriod = .monthly,
        grossRevenue: Double = 0,
        netRevenue: Double = 0,
        currency: String = "USD",
        downloads: Int? = nil
    ) {
        self.date = date
        self.period = period
        self.grossRevenue = grossRevenue
        self.netRevenue = netRevenue
        self.currency = currency
        self.downloads = downloads
    }

    // MARK: - Computed Properties

    var platformFee: Double {
        grossRevenue - netRevenue
    }

    var platformFeePercentage: Double {
        guard grossRevenue > 0 else { return 0 }
        return (platformFee / grossRevenue) * 100
    }

    var formattedGrossRevenue: String {
        formatCurrency(grossRevenue)
    }

    var formattedNetRevenue: String {
        formatCurrency(netRevenue)
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        switch period {
        case .daily:
            formatter.dateFormat = "MMM d, yyyy"
        case .weekly:
            formatter.dateFormat = "'Week of' MMM d"
        case .monthly:
            formatter.dateFormat = "MMMM yyyy"
        case .yearly:
            formatter.dateFormat = "yyyy"
        }
        return formatter.string(from: date)
    }

    var periodLabel: String {
        switch period {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        }
    }

    // MARK: - Helpers

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }

    // MARK: - Static Helpers

    static func calculateNetRevenue(gross: Double, platform: AppPlatform) -> Double {
        // Apple/Google typically take 15-30%
        let feeRate: Double
        switch platform {
        case .iOS, .macOS:
            feeRate = 0.15 // Small business program rate
        case .android:
            feeRate = 0.15
        case .web, .crossPlatform:
            feeRate = 0.03 // Payment processor only
        }
        return gross * (1 - feeRate)
    }
}

// MARK: - Revenue Period

enum RevenuePeriod: String, Codable, CaseIterable, Identifiable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case yearly = "yearly"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        }
    }
}
