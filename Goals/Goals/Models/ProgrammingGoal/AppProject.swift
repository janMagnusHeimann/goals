import Foundation
import SwiftData

@Model
final class AppProject {
    var id: UUID = UUID()
    var name: String = ""
    var platform: AppPlatform = AppPlatform.iOS
    var appStoreId: String?
    var bundleId: String?
    var iconURL: String?
    var appDescription: String?
    var launchDate: Date?
    var currentVersion: String?
    var websiteURL: String?
    var createdAt: Date = Date()
    var lastSyncedAt: Date?

    var goal: Goal?

    @Relationship(deleteRule: .cascade, inverse: \RevenueEntry.project)
    var revenueEntries: [RevenueEntry]? = []

    @Relationship(deleteRule: .cascade, inverse: \AppMetricSnapshot.project)
    var metricSnapshots: [AppMetricSnapshot]? = []

    init(
        name: String,
        platform: AppPlatform = .iOS,
        appStoreId: String? = nil,
        launchDate: Date? = nil
    ) {
        self.name = name
        self.platform = platform
        self.appStoreId = appStoreId
        self.launchDate = launchDate
    }

    // MARK: - Computed Properties

    var sortedRevenueEntries: [RevenueEntry] {
        (revenueEntries ?? []).sorted { $0.date > $1.date }
    }

    var sortedMetricSnapshots: [AppMetricSnapshot] {
        (metricSnapshots ?? []).sorted { $0.date > $1.date }
    }

    var totalRevenue: Double {
        (revenueEntries ?? []).reduce(0) { $0 + $1.netRevenue }
    }

    var totalGrossRevenue: Double {
        (revenueEntries ?? []).reduce(0) { $0 + $1.grossRevenue }
    }

    var thisMonthRevenue: Double {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        return (revenueEntries ?? [])
            .filter { $0.date >= startOfMonth }
            .reduce(0) { $0 + $1.netRevenue }
    }

    var lastMonthRevenue: Double {
        let calendar = Calendar.current
        let now = Date()
        guard let startOfThisMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)),
              let startOfLastMonth = calendar.date(byAdding: .month, value: -1, to: startOfThisMonth) else {
            return 0
        }
        return (revenueEntries ?? [])
            .filter { $0.date >= startOfLastMonth && $0.date < startOfThisMonth }
            .reduce(0) { $0 + $1.netRevenue }
    }

    var revenueGrowthPercentage: Double? {
        let lastMonth = lastMonthRevenue
        guard lastMonth > 0 else { return nil }
        return ((thisMonthRevenue - lastMonth) / lastMonth) * 100
    }

    var totalDownloads: Int {
        (revenueEntries ?? []).compactMap { $0.downloads }.reduce(0, +)
    }

    var latestRating: Double? {
        sortedMetricSnapshots.first?.rating
    }

    var latestRatingCount: Int? {
        sortedMetricSnapshots.first?.ratingCount
    }

    var latestActiveUsers: Int? {
        sortedMetricSnapshots.first?.monthlyActiveUsers
    }

    var formattedTotalRevenue: String {
        formatCurrency(totalRevenue)
    }

    var formattedThisMonthRevenue: String {
        formatCurrency(thisMonthRevenue)
    }

    var daysSinceLaunch: Int? {
        guard let launch = launchDate else { return nil }
        return Calendar.current.dateComponents([.day], from: launch, to: Date()).day
    }

    // MARK: - Helpers

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}

// MARK: - App Platform

enum AppPlatform: String, Codable, CaseIterable, Identifiable {
    case iOS = "ios"
    case macOS = "macos"
    case android = "android"
    case web = "web"
    case crossPlatform = "cross_platform"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .iOS: return "iOS"
        case .macOS: return "macOS"
        case .android: return "Android"
        case .web: return "Web"
        case .crossPlatform: return "Cross-Platform"
        }
    }

    var icon: String {
        switch self {
        case .iOS: return "iphone"
        case .macOS: return "macbook"
        case .android: return "smartphone"
        case .web: return "globe"
        case .crossPlatform: return "rectangle.on.rectangle"
        }
    }

    var storeURL: String? {
        switch self {
        case .iOS: return "https://apps.apple.com/app/id"
        case .macOS: return "https://apps.apple.com/app/id"
        case .android: return "https://play.google.com/store/apps/details?id="
        case .web, .crossPlatform: return nil
        }
    }
}

// MARK: - App Metric Snapshot

@Model
final class AppMetricSnapshot {
    var id: UUID = UUID()
    var date: Date = Date()
    var downloads: Int = 0
    var activeUsers: Int?
    var dailyActiveUsers: Int?
    var monthlyActiveUsers: Int?
    var rating: Double?
    var ratingCount: Int?
    var crashFreeRate: Double?
    var sessionsPerUser: Double?
    var retentionDay1: Double?
    var retentionDay7: Double?
    var retentionDay30: Double?
    var createdAt: Date = Date()

    var project: AppProject?

    init(date: Date = Date(), downloads: Int = 0) {
        self.date = date
        self.downloads = downloads
    }

    var formattedRating: String? {
        guard let rating = rating else { return nil }
        return String(format: "%.1f", rating)
    }

    var formattedCrashFreeRate: String? {
        guard let rate = crashFreeRate else { return nil }
        return String(format: "%.1f%%", rate)
    }
}
