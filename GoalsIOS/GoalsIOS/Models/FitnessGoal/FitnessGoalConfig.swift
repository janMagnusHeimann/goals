import Foundation
import SwiftData

@Model
final class FitnessGoalConfig {
    var id: UUID = UUID()
    var fitnessGoalType: FitnessGoalType = FitnessGoalType.consistencyGoal

    // Race Training specific
    var raceType: RaceType?
    var raceDate: Date?
    var raceName: String?
    var targetPaceSecondsPerKm: Int?
    var targetFinishTimeSeconds: Int?
    var customDistanceKm: Double?

    // Training Plan
    var currentPhase: TrainingPhase?
    var phaseStartDate: Date?
    var phaseEndDate: Date?
    var weeklyMileageTargetKm: Double?

    // Strength Goal specific
    var targetExercise: String?
    var targetWeight: Double?
    var targetReps: Int?
    var weightUnit: String = "kg"

    // Consistency Goal specific
    var sessionsPerWeek: Int?
    var minimumDurationMinutes: Int?

    // Custom Metric specific
    var metricName: String?
    var metricUnit: String?
    var targetMetricValue: Double?

    var createdAt: Date = Date()

    var goal: Goal?

    init(fitnessGoalType: FitnessGoalType = .consistencyGoal) {
        self.fitnessGoalType = fitnessGoalType
    }

    // MARK: - Computed Properties

    var daysUntilRace: Int? {
        guard let date = raceDate else { return nil }
        return max(0, Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0)
    }

    var weeksUntilRace: Int? {
        guard let days = daysUntilRace else { return nil }
        return days / 7
    }

    var raceDistanceKm: Double? {
        if let customDistance = customDistanceKm, customDistance > 0 {
            return customDistance
        }
        return raceType?.distanceKm
    }

    var targetPaceFormatted: String? {
        guard let pace = targetPaceSecondsPerKm else { return nil }
        let minutes = pace / 60
        let seconds = pace % 60
        return String(format: "%d:%02d/km", minutes, seconds)
    }

    var targetFinishTimeFormatted: String? {
        guard let time = targetFinishTimeSeconds else { return nil }
        let hours = time / 3600
        let minutes = (time % 3600) / 60
        let seconds = time % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }

    var weeklyMileageTargetFormatted: String? {
        guard let km = weeklyMileageTargetKm else { return nil }
        return String(format: "%.1f km/week", km)
    }

    var isRaceTraining: Bool {
        fitnessGoalType == .raceTraining
    }

    var isStrengthGoal: Bool {
        fitnessGoalType == .strengthGoal
    }

    var isConsistencyGoal: Bool {
        fitnessGoalType == .consistencyGoal
    }

    // MARK: - Race Pace Helpers

    func calculateFinishTime(paceSecondsPerKm: Int) -> Int? {
        guard let distance = raceDistanceKm else { return nil }
        return Int(distance * Double(paceSecondsPerKm))
    }

    func calculateRequiredPace(targetTimeSeconds: Int) -> Int? {
        guard let distance = raceDistanceKm, distance > 0 else { return nil }
        return Int(Double(targetTimeSeconds) / distance)
    }

    static func formatPace(_ secondsPerKm: Int) -> String {
        let minutes = secondsPerKm / 60
        let seconds = secondsPerKm % 60
        return String(format: "%d:%02d/km", minutes, seconds)
    }

    static func formatTime(_ totalSeconds: Int) -> String {
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }
}
