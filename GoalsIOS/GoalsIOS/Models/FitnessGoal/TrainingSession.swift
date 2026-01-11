import SwiftData
import Foundation
import SwiftUI

enum WorkoutType: String, Codable, CaseIterable, Identifiable {
    case swim = "swim"
    case bike = "bike"
    case run = "run"
    case strength = "strength"
    case recovery = "recovery"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .swim: return "Swim"
        case .bike: return "Bike"
        case .run: return "Run"
        case .strength: return "Strength"
        case .recovery: return "Recovery"
        }
    }

    var icon: String {
        switch self {
        case .swim: return "figure.pool.swim"
        case .bike: return "figure.outdoor.cycle"
        case .run: return "figure.run"
        case .strength: return "dumbbell.fill"
        case .recovery: return "heart.fill"
        }
    }

    var color: Color {
        switch self {
        case .swim: return .blue
        case .bike: return .orange
        case .run: return .green
        case .strength: return .purple
        case .recovery: return .pink
        }
    }
}

enum DistanceUnit: String, Codable, CaseIterable {
    case kilometers = "km"
    case miles = "mi"
    case meters = "m"
    case yards = "yd"

    var displayName: String { rawValue }
}

@Model
final class TrainingSession {
    var id: UUID = UUID()
    var workoutType: WorkoutType = WorkoutType.run
    var date: Date = Date()
    var durationMinutes: Int = 0
    var distance: Double?
    var distanceUnit: DistanceUnit?
    var heartRateAvg: Int?
    var heartRateMax: Int?
    var calories: Int?
    var notes: String?
    var perceivedEffort: Int?
    var createdAt: Date = Date()
    var title: String?

    // New enhanced tracking properties
    var paceSecondsPerKm: Int?
    var workoutIntent: WorkoutIntent?
    var elevationGain: Double?
    var elevationLoss: Double?
    var averageCadence: Int?
    var weatherConditions: String?
    var isRace: Bool = false
    var racePosition: Int?
    var raceFieldSize: Int?

    var goal: Goal?

    var formattedDuration: String {
        let hours = durationMinutes / 60
        let minutes = durationMinutes % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    var formattedDistance: String? {
        guard let distance = distance, let unit = distanceUnit else { return nil }
        return String(format: "%.2f %@", distance, unit.rawValue)
    }

    var displayTitle: String {
        if let title = title, !title.isEmpty {
            return title
        }
        return "\(workoutType.displayName) - \(formattedDuration)"
    }

    var effortDescription: String? {
        guard let effort = perceivedEffort else { return nil }
        switch effort {
        case 1...3: return "Easy"
        case 4...6: return "Moderate"
        case 7...8: return "Hard"
        case 9...10: return "Maximum"
        default: return nil
        }
    }

    // MARK: - Pace Properties

    var formattedPace: String? {
        guard let pace = paceSecondsPerKm else { return nil }
        let minutes = pace / 60
        let seconds = pace % 60
        return String(format: "%d:%02d/km", minutes, seconds)
    }

    var formattedPaceMiles: String? {
        guard let pace = paceSecondsPerKm else { return nil }
        let pacePerMile = Int(Double(pace) * 1.60934)
        let minutes = pacePerMile / 60
        let seconds = pacePerMile % 60
        return String(format: "%d:%02d/mi", minutes, seconds)
    }

    var formattedElevation: String? {
        guard let gain = elevationGain else { return nil }
        if let loss = elevationLoss {
            return String(format: "+%.0fm / -%.0fm", gain, loss)
        }
        return String(format: "+%.0fm", gain)
    }

    var workoutIntentColor: Color {
        workoutIntent?.color ?? .gray
    }

    var workoutIntentLabel: String {
        workoutIntent?.displayName ?? "Workout"
    }

    var distanceKm: Double? {
        guard let dist = distance, let unit = distanceUnit else { return nil }
        switch unit {
        case .kilometers: return dist
        case .miles: return dist * 1.60934
        case .meters: return dist / 1000
        case .yards: return dist * 0.0009144
        }
    }

    var calculatedPaceSecondsPerKm: Int? {
        guard let km = distanceKm, km > 0, durationMinutes > 0 else { return nil }
        return Int((Double(durationMinutes) * 60) / km)
    }

    // Auto-calculate pace if not set
    var effectivePace: Int? {
        paceSecondsPerKm ?? calculatedPaceSecondsPerKm
    }

    var raceResult: String? {
        guard isRace, let position = racePosition else { return nil }
        if let fieldSize = raceFieldSize {
            return "\(position)/\(fieldSize)"
        }
        return "#\(position)"
    }

    init(workoutType: WorkoutType, date: Date = Date(), durationMinutes: Int) {
        self.workoutType = workoutType
        self.date = date
        self.durationMinutes = durationMinutes
    }
}
