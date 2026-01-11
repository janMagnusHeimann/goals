import SwiftUI

struct TrainingPhaseTimeline: View {
    let config: FitnessGoalConfig
    var compact: Bool = false

    private let phases: [TrainingPhase] = [.base, .build, .peak, .taper]

    private var currentPhaseIndex: Int {
        guard let current = config.currentPhase else { return 0 }
        return phases.firstIndex(of: current) ?? 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !compact {
                HStack {
                    Image(systemName: "figure.run.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.orange)
                    Text("Training Plan")
                        .font(.headline)
                    Spacer()

                    if let days = config.daysUntilRace {
                        Text("\(days) days to race")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Timeline
            GeometryReader { geometry in
                let segmentWidth = geometry.size.width / CGFloat(phases.count)

                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 8)

                    // Progress fill
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [.blue, .orange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: segmentWidth * CGFloat(currentPhaseIndex + 1), height: 8)

                    // Phase markers
                    HStack(spacing: 0) {
                        ForEach(Array(phases.enumerated()), id: \.element) { index, phase in
                            VStack(spacing: 8) {
                                // Marker
                                Circle()
                                    .fill(index <= currentPhaseIndex ? phase.color : Color.secondary.opacity(0.3))
                                    .frame(width: compact ? 12 : 16, height: compact ? 12 : 16)
                                    .overlay {
                                        if index < currentPhaseIndex {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: compact ? 6 : 8, weight: .bold))
                                                .foregroundStyle(.white)
                                        } else if index == currentPhaseIndex {
                                            Circle()
                                                .fill(.white)
                                                .frame(width: compact ? 4 : 6, height: compact ? 4 : 6)
                                        }
                                    }

                                // Label
                                if !compact {
                                    VStack(spacing: 2) {
                                        Text(phase.displayName)
                                            .font(.caption)
                                            .fontWeight(index == currentPhaseIndex ? .semibold : .regular)
                                            .foregroundStyle(index == currentPhaseIndex ? .primary : .secondary)

                                        if index == currentPhaseIndex {
                                            Text("Current")
                                                .font(.system(size: 9))
                                                .foregroundStyle(phase.color)
                                        }
                                    }
                                }
                            }
                            .frame(width: segmentWidth)
                        }
                    }
                }
            }
            .frame(height: compact ? 20 : 60)

            // Current phase details
            if !compact, let current = config.currentPhase {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(current.displayName)
                            .font(.title3)
                            .fontWeight(.semibold)
                        Text(current.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Phase intensity indicator
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Intensity")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack(spacing: 2) {
                            ForEach(1...5, id: \.self) { level in
                                Rectangle()
                                    .fill(level <= current.intensityLevel ? current.color : Color.secondary.opacity(0.2))
                                    .frame(width: 8, height: CGFloat(level * 4 + 8))
                                    .clipShape(RoundedRectangle(cornerRadius: 2))
                            }
                        }
                    }
                }
                .padding()
                .background(current.color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(compact ? 0 : 16)
        .background(compact ? Color.clear : Color.goalCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: compact ? 0 : 16))
    }
}

// MARK: - Phase Badge

struct PhaseBadge: View {
    let phase: TrainingPhase

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(phase.color)
                .frame(width: 8, height: 8)
            Text(phase.displayName)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(phase.color.opacity(0.15))
        .clipShape(Capsule())
    }
}

// MARK: - Preview

#Preview {
    let config = FitnessGoalConfig(fitnessGoalType: .raceTraining)
    config.raceType = .marathon
    config.raceDate = Calendar.current.date(byAdding: .day, value: 90, to: Date())
    config.currentPhase = .build

    return VStack(spacing: 20) {
        TrainingPhaseTimeline(config: config)

        TrainingPhaseTimeline(config: config, compact: true)
            .padding(.horizontal)

        HStack {
            PhaseBadge(phase: .base)
            PhaseBadge(phase: .build)
            PhaseBadge(phase: .peak)
            PhaseBadge(phase: .taper)
        }
    }
    .padding()
    .frame(width: 500)
}
