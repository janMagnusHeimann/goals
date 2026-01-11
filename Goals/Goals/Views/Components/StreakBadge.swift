import SwiftUI

struct StreakBadge: View {
    let streakDays: Int
    var icon: String = "flame.fill"
    var size: StreakSize = .medium

    private var flameColor: Color {
        switch streakDays {
        case 0: return .gray
        case 1...6: return .orange
        case 7...29: return .orange
        case 30...99: return .red
        default: return .purple
        }
    }

    private var backgroundColor: Color {
        flameColor.opacity(0.15)
    }

    var body: some View {
        HStack(spacing: size.spacing) {
            Image(systemName: icon)
                .font(.system(size: size.iconSize))
                .foregroundStyle(
                    streakDays > 0
                        ? LinearGradient(colors: [.yellow, flameColor], startPoint: .top, endPoint: .bottom)
                        : LinearGradient(colors: [.gray, .gray], startPoint: .top, endPoint: .bottom)
                )
                .symbolEffect(.pulse, options: .repeating, value: streakDays > 6)

            Text("\(streakDays)")
                .font(.system(size: size.fontSize, weight: .bold, design: .rounded))
                .foregroundStyle(streakDays > 0 ? flameColor : .gray)

            if size != .small {
                Text(streakDays == 1 ? "day" : "days")
                    .font(.system(size: size.fontSize * 0.7))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, size.padding)
        .padding(.vertical, size.padding * 0.6)
        .background(backgroundColor)
        .clipShape(Capsule())
    }

    enum StreakSize {
        case small, medium, large

        var iconSize: CGFloat {
            switch self {
            case .small: return 12
            case .medium: return 16
            case .large: return 24
            }
        }

        var fontSize: CGFloat {
            switch self {
            case .small: return 12
            case .medium: return 16
            case .large: return 24
            }
        }

        var spacing: CGFloat {
            switch self {
            case .small: return 2
            case .medium: return 4
            case .large: return 6
            }
        }

        var padding: CGFloat {
            switch self {
            case .small: return 6
            case .medium: return 10
            case .large: return 14
            }
        }
    }
}

// MARK: - Streak Card (Larger display)

struct StreakCard: View {
    let title: String
    let currentStreak: Int
    let longestStreak: Int
    var icon: String = "flame.fill"

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.orange)
                Text(title)
                    .font(.headline)
                Spacer()
            }

            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 4) {
                        Text("\(currentStreak)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                        Text("days")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Divider()
                    .frame(height: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Longest")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 4) {
                        Text("\(longestStreak)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                        Text("days")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
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
            StreakBadge(streakDays: 0, size: .small)
            StreakBadge(streakDays: 3, size: .small)
            StreakBadge(streakDays: 7, size: .small)
            StreakBadge(streakDays: 30, size: .small)
            StreakBadge(streakDays: 100, size: .small)
        }

        HStack(spacing: 12) {
            StreakBadge(streakDays: 5, size: .medium)
            StreakBadge(streakDays: 14, size: .medium)
        }

        StreakBadge(streakDays: 42, size: .large)

        StreakCard(title: "Reading Streak", currentStreak: 14, longestStreak: 32)
            .frame(width: 300)
    }
    .padding()
}
