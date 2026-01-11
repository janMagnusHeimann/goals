import SwiftUI

struct AppProjectCard: View {
    let project: AppProject
    var showFullDetails: Bool = false
    var onTap: (() -> Void)?

    var body: some View {
        Button {
            onTap?()
        } label: {
            HStack(spacing: 16) {
                // App Icon
                AppIconView(iconURL: project.iconURL, platform: project.platform)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(project.name)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Image(systemName: project.platform.icon)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if project.launchDate != nil,
                       let days = project.daysSinceLaunch {
                        Text("Launched \(days) days ago")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else if project.launchDate == nil {
                        Text("In Development")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }

                Spacer()

                // Revenue info
                VStack(alignment: .trailing, spacing: 4) {
                    Text(project.formattedThisMonthRevenue)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.green)

                    if let growth = project.revenueGrowthPercentage {
                        HStack(spacing: 2) {
                            Image(systemName: growth >= 0 ? "arrow.up.right" : "arrow.down.right")
                                .font(.caption2)
                            Text(String(format: "%.0f%%", abs(growth)))
                        }
                        .font(.caption)
                        .foregroundStyle(growth >= 0 ? .green : .red)
                    } else {
                        Text("this month")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .background(Color.goalCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - App Icon View

struct AppIconView: View {
    let iconURL: String?
    let platform: AppPlatform
    var size: CGFloat = 48

    var body: some View {
        Group {
            if let urlString = iconURL,
               let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        placeholderIcon
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    case .failure:
                        placeholderIcon
                    @unknown default:
                        placeholderIcon
                    }
                }
            } else {
                placeholderIcon
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22))
    }

    private var placeholderIcon: some View {
        ZStack {
            LinearGradient(
                colors: [.blue, .purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Image(systemName: platform.icon)
                .font(.system(size: size * 0.4))
                .foregroundStyle(.white)
        }
    }
}

// MARK: - Compact App Project Card

struct CompactAppProjectCard: View {
    let project: AppProject

    var body: some View {
        VStack(spacing: 12) {
            AppIconView(iconURL: project.iconURL, platform: project.platform, size: 56)

            VStack(spacing: 4) {
                Text(project.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Text(project.formattedThisMonthRevenue)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.green)
            }

            if let rating = project.latestRating {
                HStack(spacing: 2) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                    Text(String(format: "%.1f", rating))
                }
                .font(.caption)
            }
        }
        .padding()
        .background(Color.goalCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - App Projects List

struct AppProjectsList: View {
    let projects: [AppProject]
    var onAddProject: (() -> Void)?
    var onSelectProject: ((AppProject) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "app.badge.fill")
                    .font(.title2)
                    .foregroundStyle(.purple)
                Text("App Projects")
                    .font(.headline)
                Spacer()

                if let onAdd = onAddProject {
                    Button(action: onAdd) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }

            if projects.isEmpty {
                ContentUnavailableView {
                    Label("No Apps Yet", systemImage: "app.dashed")
                } description: {
                    Text("Add your first app project to track revenue and metrics")
                } actions: {
                    if let onAdd = onAddProject {
                        Button("Add App Project", action: onAdd)
                            .buttonStyle(.borderedProminent)
                    }
                }
                .frame(height: 150)
            } else {
                VStack(spacing: 8) {
                    ForEach(projects.sorted { $0.thisMonthRevenue > $1.thisMonthRevenue }) { project in
                        AppProjectCard(project: project) {
                            onSelectProject?(project)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.goalCardBackground.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Preview

#Preview {
    let project1 = AppProject(name: "Goals Tracker", platform: .iOS, launchDate: Calendar.current.date(byAdding: .month, value: -6, to: Date()))
    let project2 = AppProject(name: "Habit Builder", platform: .macOS)

    // Add some revenue entries
    let entry1 = RevenueEntry(date: Date(), period: .monthly, grossRevenue: 1500, netRevenue: 1275)
    let entry2 = RevenueEntry(
        date: Calendar.current.date(byAdding: .month, value: -1, to: Date())!,
        period: .monthly,
        grossRevenue: 1200,
        netRevenue: 1020
    )
    project1.revenueEntries = [entry1, entry2]

    return VStack(spacing: 20) {
        AppProjectCard(project: project1)

        HStack {
            CompactAppProjectCard(project: project1)
            CompactAppProjectCard(project: project2)
        }

        AppProjectsList(projects: [project1, project2])
    }
    .padding()
    .frame(width: 500)
}
