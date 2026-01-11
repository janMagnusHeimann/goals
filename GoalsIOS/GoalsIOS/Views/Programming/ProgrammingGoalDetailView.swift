import SwiftUI
import SwiftData

struct ProgrammingGoalDetailView: View {
    @Bindable var goal: Goal

    @Environment(\.modelContext) private var modelContext
    @StateObject private var authService = GitHubAuthService()
    @State private var showingAddRepo = false
    @State private var showingAddAppProject = false
    @State private var showingAddRevenue = false
    @State private var selectedAppProject: AppProject?
    @State private var selectedTab: ProgrammingTab = .repositories

    enum ProgrammingTab: String, CaseIterable {
        case repositories = "Repos"
        case apps = "Apps"
        case revenue = "Revenue"
    }

    private var hasAppProjects: Bool {
        !(goal.appProjects ?? []).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            // Tab selector
            Picker("Tab", selection: $selectedTab) {
                ForEach(ProgrammingTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            List {
                switch selectedTab {
                case .repositories:
                    repositoriesSections
                case .apps:
                    appsSections
                case .revenue:
                    revenueSections
                }
            }
        }
        .navigationTitle(goal.title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    if authService.isAuthenticated {
                        Button {
                            showingAddRepo = true
                        } label: {
                            Label("Add Repository", systemImage: "folder.badge.plus")
                        }
                    }

                    Button {
                        showingAddAppProject = true
                    } label: {
                        Label("Add App Project", systemImage: "app.badge.fill")
                    }

                    if let project = selectedAppProject ?? (goal.appProjects ?? []).first {
                        Button {
                            selectedAppProject = project
                            showingAddRevenue = true
                        } label: {
                            Label("Log Revenue", systemImage: "dollarsign.circle")
                        }
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddRepo) {
            AddRepositorySheet(goal: goal, authService: authService)
        }
        .sheet(isPresented: $showingAddAppProject) {
            AddAppProjectSheet(goal: goal) { project in
                modelContext.insert(project)
                project.goal = goal
            }
        }
        .sheet(isPresented: $showingAddRevenue) {
            if let project = selectedAppProject ?? (goal.appProjects ?? []).first {
                AddRevenueSheet(project: project) { entry in
                    modelContext.insert(entry)
                    entry.project = project
                }
            }
        }
        .onChange(of: goal.repositories?.count) {
            goal.updateProgress()
        }
    }

    // MARK: - Repositories Sections

    @ViewBuilder
    private var repositoriesSections: some View {
        // Progress Section
        Section {
            VStack(spacing: 16) {
                HStack {
                    ProgressRing(progress: goal.progress, color: .purple)
                        .frame(width: 80, height: 80)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(goal.currentValue) of \(goal.targetValue) commits")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("\(goal.progressPercentage)% complete")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
            }
            .padding(.vertical, 8)
        }

        // GitHub Stats
        if !goal.sortedRepositories.isEmpty {
            Section("GitHub Stats") {
                HStack {
                    VStack {
                        Text("\(goal.totalGitHubStars)")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Stars")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)

                    Divider()

                    VStack {
                        Text("\(goal.sortedRepositories.reduce(0) { $0 + $1.forks })")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Forks")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)

                    Divider()

                    VStack {
                        Text("\(goal.sortedRepositories.count)")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Repos")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 8)
            }
        }

        if !authService.isAuthenticated {
            Section {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundStyle(.orange)

                    Text("Connect GitHub to track repositories")
                        .font(.headline)

                    Text("Go to Settings to connect your GitHub account")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
        }

        Section("Repositories") {
            if goal.sortedRepositories.isEmpty {
                Text("No repositories linked yet")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(goal.sortedRepositories) { repo in
                    RepositoryRowView(repository: repo)
                }
                .onDelete(perform: deleteRepositories)
            }
        }
    }

    // MARK: - Apps Sections

    @ViewBuilder
    private var appsSections: some View {
        // Revenue Summary
        if hasAppProjects {
            Section("Revenue Summary") {
                HStack {
                    VStack(alignment: .leading) {
                        Text(goal.formattedThisMonthAppRevenue)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.green)
                        Text("this month")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing) {
                        Text(goal.formattedTotalAppRevenue)
                            .font(.headline)
                        Text("all time")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }

        Section("App Projects") {
            if (goal.appProjects ?? []).isEmpty {
                ContentUnavailableView {
                    Label("No Apps Yet", systemImage: "app.dashed")
                } description: {
                    Text("Add your first app project")
                } actions: {
                    Button("Add App") {
                        showingAddAppProject = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                ForEach(goal.appProjects ?? []) { project in
                    AppProjectRowView(project: project) {
                        selectedAppProject = project
                        showingAddRevenue = true
                    }
                }
                .onDelete(perform: deleteAppProjects)
            }
        }
    }

    // MARK: - Revenue Sections

    @ViewBuilder
    private var revenueSections: some View {
        if hasAppProjects {
            // Total Revenue
            Section("Total Revenue") {
                VStack(alignment: .leading, spacing: 8) {
                    Text(goal.formattedTotalAppRevenue)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.green)

                    Text("across \((goal.appProjects ?? []).count) apps")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }

            // Revenue by App
            Section("By App") {
                ForEach((goal.appProjects ?? []).sorted { $0.totalRevenue > $1.totalRevenue }) { project in
                    HStack {
                        AppIconView(iconURL: project.iconURL, platform: project.platform, size: 40)

                        VStack(alignment: .leading) {
                            Text(project.name)
                                .font(.headline)
                            Text(project.platform.displayName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing) {
                            Text(project.formattedTotalRevenue)
                                .font(.headline)
                                .foregroundStyle(.green)
                            Text(project.formattedThisMonthRevenue)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        } else {
            Section {
                ContentUnavailableView {
                    Label("No Revenue Data", systemImage: "chart.bar")
                } description: {
                    Text("Add app projects to track revenue")
                } actions: {
                    Button("Add App Project") {
                        showingAddAppProject = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }

    // MARK: - Helpers

    private func deleteRepositories(at offsets: IndexSet) {
        let repos = goal.sortedRepositories
        for index in offsets {
            modelContext.delete(repos[index])
        }
        goal.updateProgress()
    }

    private func deleteAppProjects(at offsets: IndexSet) {
        let projects = goal.appProjects ?? []
        for index in offsets {
            modelContext.delete(projects[index])
        }
    }
}

// MARK: - Repository Row View

struct RepositoryRowView: View {
    let repository: GitHubRepository

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: repository.isPrivate ? "lock.fill" : "globe")
                    .foregroundStyle(.secondary)

                Text(repository.fullName)
                    .font(.headline)
            }

            HStack(spacing: 16) {
                if let language = repository.language {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.forLanguage(language))
                            .frame(width: 10, height: 10)
                        Text(language)
                            .font(.caption)
                    }
                }

                Label("\(repository.starCount)", systemImage: "star")
                    .font(.caption)

                Label("\(repository.totalCommits)", systemImage: "arrow.triangle.branch")
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - App Project Row View

struct AppProjectRowView: View {
    let project: AppProject
    let onLogRevenue: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            AppIconView(iconURL: project.iconURL, platform: project.platform, size: 50)

            VStack(alignment: .leading, spacing: 4) {
                Text(project.name)
                    .font(.headline)

                HStack(spacing: 8) {
                    Label(project.platform.displayName, systemImage: project.platform.icon)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let days = project.daysSinceLaunch {
                        Text("\(days) days")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(project.formattedThisMonthRevenue)
                    .font(.headline)
                    .foregroundStyle(.green)

                if let growth = project.revenueGrowthPercentage {
                    HStack(spacing: 2) {
                        Image(systemName: growth >= 0 ? "arrow.up" : "arrow.down")
                            .font(.caption2)
                        Text(String(format: "%.0f%%", abs(growth)))
                    }
                    .font(.caption)
                    .foregroundStyle(growth >= 0 ? .green : .red)
                }
            }
        }
        .padding(.vertical, 4)
        .swipeActions(edge: .trailing) {
            Button {
                onLogRevenue()
            } label: {
                Label("Log Revenue", systemImage: "dollarsign.circle")
            }
            .tint(.green)
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Goal.self, configurations: config)
    let goal = Goal(title: "Contribute to Open Source", goalType: .programming, targetValue: 500)
    container.mainContext.insert(goal)

    return NavigationStack {
        ProgrammingGoalDetailView(goal: goal)
    }
    .modelContainer(container)
}
