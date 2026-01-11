import Foundation
import SwiftUI

// MARK: - Fitness Goal Type

enum FitnessGoalType: String, Codable, CaseIterable, Identifiable {
    case raceTraining = "race_training"
    case strengthGoal = "strength_goal"
    case consistencyGoal = "consistency_goal"
    case customMetric = "custom_metric"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .raceTraining: return "Race Training"
        case .strengthGoal: return "Strength Goal"
        case .consistencyGoal: return "Consistency Goal"
        case .customMetric: return "Custom Metric"
        }
    }

    var icon: String {
        switch self {
        case .raceTraining: return "flag.checkered"
        case .strengthGoal: return "dumbbell.fill"
        case .consistencyGoal: return "calendar.badge.clock"
        case .customMetric: return "slider.horizontal.3"
        }
    }

    var description: String {
        switch self {
        case .raceTraining: return "Train for a race with pace and mileage goals"
        case .strengthGoal: return "Track personal records and strength progression"
        case .consistencyGoal: return "Build habits with workout frequency goals"
        case .customMetric: return "Track any custom fitness metric"
        }
    }

    var color: Color {
        switch self {
        case .raceTraining: return .orange
        case .strengthGoal: return .purple
        case .consistencyGoal: return .green
        case .customMetric: return .blue
        }
    }
}

// MARK: - Race Type

enum RaceType: String, Codable, CaseIterable, Identifiable {
    case fiveK = "5k"
    case tenK = "10k"
    case halfMarathon = "half_marathon"
    case marathon = "marathon"
    case triathlon = "triathlon"
    case custom = "custom"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fiveK: return "5K"
        case .tenK: return "10K"
        case .halfMarathon: return "Half Marathon"
        case .marathon: return "Marathon"
        case .triathlon: return "Triathlon"
        case .custom: return "Custom Distance"
        }
    }

    var distanceKm: Double {
        switch self {
        case .fiveK: return 5.0
        case .tenK: return 10.0
        case .halfMarathon: return 21.0975
        case .marathon: return 42.195
        case .triathlon: return 51.5 // Olympic triathlon total
        case .custom: return 0
        }
    }

    var distanceMiles: Double {
        distanceKm * 0.621371
    }

    var icon: String {
        switch self {
        case .fiveK, .tenK: return "figure.run"
        case .halfMarathon, .marathon: return "figure.run.circle.fill"
        case .triathlon: return "figure.mixed.cardio"
        case .custom: return "ruler"
        }
    }
}

// MARK: - Training Phase

enum TrainingPhase: String, Codable, CaseIterable, Identifiable {
    case base = "base"
    case build = "build"
    case peak = "peak"
    case taper = "taper"
    case recovery = "recovery"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .base: return "Base"
        case .build: return "Build"
        case .peak: return "Peak"
        case .taper: return "Taper"
        case .recovery: return "Recovery"
        }
    }

    var description: String {
        switch self {
        case .base: return "Building aerobic foundation"
        case .build: return "Increasing intensity and volume"
        case .peak: return "Race-specific training"
        case .taper: return "Reducing volume before race"
        case .recovery: return "Post-race recovery"
        }
    }

    var color: Color {
        switch self {
        case .base: return .blue
        case .build: return .orange
        case .peak: return .red
        case .taper: return .green
        case .recovery: return .purple
        }
    }

    var intensityLevel: Int {
        switch self {
        case .base: return 1
        case .build: return 3
        case .peak: return 4
        case .taper: return 2
        case .recovery: return 1
        }
    }
}

// MARK: - Workout Intent

enum WorkoutIntent: String, Codable, CaseIterable, Identifiable {
    case easy = "easy"
    case tempo = "tempo"
    case interval = "interval"
    case longRun = "long_run"
    case recovery = "recovery"
    case race = "race"
    case strength = "strength"
    case crossTraining = "cross_training"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .easy: return "Easy"
        case .tempo: return "Tempo"
        case .interval: return "Interval"
        case .longRun: return "Long Run"
        case .recovery: return "Recovery"
        case .race: return "Race"
        case .strength: return "Strength"
        case .crossTraining: return "Cross Training"
        }
    }

    var icon: String {
        switch self {
        case .easy: return "tortoise.fill"
        case .tempo: return "speedometer"
        case .interval: return "arrow.up.arrow.down"
        case .longRun: return "road.lanes"
        case .recovery: return "leaf.fill"
        case .race: return "flag.checkered"
        case .strength: return "dumbbell.fill"
        case .crossTraining: return "figure.mixed.cardio"
        }
    }

    var color: Color {
        switch self {
        case .easy: return .green
        case .tempo: return .yellow
        case .interval: return .orange
        case .longRun: return .blue
        case .recovery: return .mint
        case .race: return .red
        case .strength: return .purple
        case .crossTraining: return .cyan
        }
    }

    var targetEffortRange: ClosedRange<Int> {
        switch self {
        case .easy: return 1...3
        case .tempo: return 6...7
        case .interval: return 8...9
        case .longRun: return 4...6
        case .recovery: return 1...2
        case .race: return 8...10
        case .strength: return 5...8
        case .crossTraining: return 3...6
        }
    }

    var description: String {
        switch self {
        case .easy: return "Conversational pace, build aerobic base"
        case .tempo: return "Comfortably hard, sustainable effort"
        case .interval: return "High intensity with rest periods"
        case .longRun: return "Extended duration at easy pace"
        case .recovery: return "Very light activity for recovery"
        case .race: return "Race day or time trial effort"
        case .strength: return "Resistance or weight training"
        case .crossTraining: return "Alternative cardio activity"
        }
    }
}
