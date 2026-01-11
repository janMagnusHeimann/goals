import Foundation
import SwiftData

@Model
final class PersonalRecord {
    var id: UUID = UUID()
    var exercise: String = ""
    var category: PRCategory = PRCategory.running
    var value: Double = 0
    var unit: String = ""
    var achievedDate: Date = Date()
    var notes: String?
    var previousValue: Double?
    var previousDate: Date?
    var createdAt: Date = Date()

    var goal: Goal?

    init(
        exercise: String,
        category: PRCategory = .running,
        value: Double,
        unit: String,
        achievedDate: Date = Date(),
        notes: String? = nil
    ) {
        self.exercise = exercise
        self.category = category
        self.value = value
        self.unit = unit
        self.achievedDate = achievedDate
        self.notes = notes
    }

    // MARK: - Computed Properties

    var improvement: Double? {
        guard let prev = previousValue else { return nil }
        return value - prev
    }

    var improvementPercentage: Double? {
        guard let prev = previousValue, prev > 0 else { return nil }
        return ((value - prev) / prev) * 100
    }

    var isImprovement: Bool {
        guard let prev = previousValue else { return true }
        switch category {
        case .running, .cycling, .swimming:
            // For time-based records, lower is better
            return value < prev
        case .strength, .custom:
            // For weight/reps, higher is better
            return value > prev
        }
    }

    var formattedValue: String {
        switch category {
        case .running, .cycling, .swimming:
            // Format as time
            let totalSeconds = Int(value)
            let hours = totalSeconds / 3600
            let minutes = (totalSeconds % 3600) / 60
            let seconds = totalSeconds % 60
            if hours > 0 {
                return String(format: "%d:%02d:%02d", hours, minutes, seconds)
            }
            return String(format: "%d:%02d", minutes, seconds)
        case .strength:
            return String(format: "%.1f %@", value, unit)
        case .custom:
            return String(format: "%.1f %@", value, unit)
        }
    }

    var formattedImprovement: String? {
        guard let imp = improvement else { return nil }
        let sign = imp > 0 ? "+" : ""
        switch category {
        case .running, .cycling, .swimming:
            let absImp = abs(Int(imp))
            let minutes = absImp / 60
            let seconds = absImp % 60
            let direction = imp < 0 ? "faster" : "slower"
            if minutes > 0 {
                return "\(minutes)m \(seconds)s \(direction)"
            }
            return "\(seconds)s \(direction)"
        case .strength, .custom:
            return String(format: "%@%.1f %@", sign, imp, unit)
        }
    }

    var displayTitle: String {
        "\(exercise) PR"
    }
}

// MARK: - PR Category

enum PRCategory: String, Codable, CaseIterable, Identifiable {
    case running = "running"
    case cycling = "cycling"
    case swimming = "swimming"
    case strength = "strength"
    case custom = "custom"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .running: return "Running"
        case .cycling: return "Cycling"
        case .swimming: return "Swimming"
        case .strength: return "Strength"
        case .custom: return "Custom"
        }
    }

    var icon: String {
        switch self {
        case .running: return "figure.run"
        case .cycling: return "figure.outdoor.cycle"
        case .swimming: return "figure.pool.swim"
        case .strength: return "dumbbell.fill"
        case .custom: return "star.fill"
        }
    }

    var defaultUnit: String {
        switch self {
        case .running, .cycling, .swimming: return "seconds"
        case .strength: return "kg"
        case .custom: return ""
        }
    }

    var commonExercises: [String] {
        switch self {
        case .running: return ["5K", "10K", "Half Marathon", "Marathon", "Mile", "400m"]
        case .cycling: return ["40K TT", "100K", "FTP Test", "1 Hour"]
        case .swimming: return ["100m Freestyle", "400m IM", "1500m", "50m Sprint"]
        case .strength: return ["Bench Press", "Squat", "Deadlift", "Overhead Press", "Pull-ups"]
        case .custom: return []
        }
    }
}
