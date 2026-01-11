import SwiftUI
import SwiftData
import Charts

struct ProgrammingGoalDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var authService = GitHubAuthService()
    @Bindable var goal: Goal
    @State private var showingAddRepo = false
    @State private var showingAddAppProject = false
    @State private var showingAddRevenue = false
    @State private var selectedAppProject: AppProject?
    @State private var isLoading = false
    @State private var error: String?
    @State private var selectedTab: ProgrammingTab = .repositories

    enum ProgrammingTab: String, CaseIterable {
        case repositories = "Repositories"
        case apps = "Apps"
        case revenue = "Revenue"
    }

    private let apiService = GitHubAPIService()

    private var hasAppProjects: Bool {
        !(goal.appProjects ?? []).isEmpty
    }

    private var allRevenueEntries: [RevenueEntry] {
        (goal.appProjects ?? []).flatMap { $0.sortedRevenueEntries }
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

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    switch selectedTab {
                    case .repositories:
                        repositoriesTabContent
                    case .apps:
                        appsTabContent
                    case .revenue:
                        revenueTabContent
                    }
                }
                .padding(24)
            }
        }
        .background(Color.goalSecondaryBackground)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
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
                    Label("Add", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddRepo) {
            AddRepositorySheet(
                goal: goal,
                authService: authService
            ) { repo in
                modelContext.insert(repo)
                repo.goal = goal
                goal.updateProgress()
                Task {
                    await syncRepository(repo)
                }
            }
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
        .alert("Error", isPresented: .constant(error != nil)) {
            Button("OK") { error = nil }
        } message: {
            Text(error ?? "")
        }
    }

    // MARK: - Repositories Tab

    @ViewBuilder
    private var repositoriesTabContent: some View {
        GoalProgressHeader(goal: goal)

        if !authService.isAuthenticated {
            githubConnectSection
        } else {
            connectedUserSection

            // GitHub Stats Summary
            if !goal.sortedRepositories.isEmpty {
                StarsSummaryCard(repositories: goal.sortedRepositories)
            }

            statsOverview

            if !goal.sortedRepositories.isEmpty {
                StarTrendChart(repositories: goal.sortedRepositories)
                commitActivityChart
            }

            repositoriesSection
        }
    }

    // MARK: - Apps Tab

    @ViewBuilder
    private var appsTabContent: some View {
        if hasAppProjects {
            RevenueSummaryCard(projects: goal.appProjects ?? [])
        }

        AppProjectsList(
            projects: goal.appProjects ?? [],
            onAddProject: {
                showingAddAppProject = true
            },
            onSelectProject: { project in
                selectedAppProject = project
            }
        )

        // Selected project details
        if let project = selectedAppProject {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Revenue History")
                        .font(.headline)
                    Spacer()
                    Button("Log Revenue") {
                        showingAddRevenue = true
                    }
                    .buttonStyle(.bordered)
                }

                if !project.sortedRevenueEntries.isEmpty {
                    RevenueChart(entries: project.sortedRevenueEntries)
                }

                RevenueHistoryView(
                    project: project,
                    onAddRevenue: {
                        showingAddRevenue = true
                    },
                    onDeleteEntry: { entry in
                        modelContext.delete(entry)
                    }
                )
            }
        }
    }

    // MARK: - Revenue Tab

    @ViewBuilder
    private var revenueTabContent: some View {
        if hasAppProjects {
            RevenueSummaryCard(projects: goal.appProjects ?? [])

            RevenueChart(entries: allRevenueEntries)

            // Revenue by app
            VStack(alignment: .leading, spacing: 12) {
                Text("Revenue by App")
                    .font(.headline)

                ForEach((goal.appProjects ?? []).sorted { $0.totalRevenue > $1.totalRevenue }) { project in
                    AppRevenueRow(project: project) {
                        selectedAppProject = project
                        selectedTab = .apps
                    }
                }
            }
            .padding()
            .background(Color.goalCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        } else {
            ContentUnavailableView {
                Label("No App Projects", systemImage: "app.dashed")
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

    private var githubConnectSection: some View {
        VStack(spacing: 20) {
            Image(systemName: "chevron.left.forwardslash.chevron.right")
                .font(.system(size: 48))
                .foregroundStyle(.purple)

            Text("Connect GitHub")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Link your GitHub account to track commits and repository activity")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)

            Button {
                connectGitHub()
            } label: {
                HStack {
                    Image(systemName: "link")
                    Text("Connect GitHub Account")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(authService.isLoading)

            if authService.isLoading {
                ProgressView()
            }

            Text("Configure your GitHub OAuth credentials in Settings first")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Color.goalCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var connectedUserSection: some View {
        HStack(spacing: 16) {
            if let user = authService.user {
                AsyncImage(url: URL(string: user.avatarURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color.secondary.opacity(0.2))
                }
                .frame(width: 48, height: 48)
                .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(user.name ?? user.login)
                        .font(.headline)

                    Text("@\(user.login)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(user.publicRepos) repos")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("\(user.followers) followers")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Button("Disconnect") {
                    authService.signOut()
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.red)
            }
        }
        .padding()
        .background(Color.goalCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var statsOverview: some View {
        HStack(spacing: 16) {
            StatCard(
                title: "Repositories",
                value: "\(goal.sortedRepositories.count)",
                icon: "folder.fill",
                color: .purple
            )

            StatCard(
                title: "Total Commits",
                value: "\(totalCommits)",
                icon: "arrow.triangle.branch",
                color: .green
            )

            StatCard(
                title: "Recent (4 weeks)",
                value: "\(recentCommits)",
                icon: "clock.fill",
                color: .blue
            )

            StatCard(
                title: "Stars",
                value: "\(totalStars)",
                icon: "star.fill",
                color: .yellow
            )
        }
    }

    private var totalCommits: Int {
        goal.sortedRepositories.reduce(0) { $0 + $1.totalCommits }
    }

    private var recentCommits: Int {
        goal.sortedRepositories.reduce(0) { $0 + $1.recentCommits }
    }

    private var totalStars: Int {
        goal.sortedRepositories.reduce(0) { $0 + $1.starCount }
    }

    private var commitActivityChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Commit Activity")
                .font(.headline)

            let allActivities = goal.sortedRepositories.flatMap { $0.sortedCommitActivities }
            let grouped = Dictionary(grouping: allActivities) { activity in
                Calendar.current.startOfDay(for: activity.weekStartDate)
            }
            let chartData = grouped.map { (date: $0.key, count: $0.value.reduce(0) { $0 + $1.commitCount }) }
                .sorted { $0.date < $1.date }

            if !chartData.isEmpty {
                Chart(chartData, id: \.date) { item in
                    BarMark(
                        x: .value("Week", item.date, unit: .weekOfYear),
                        y: .value("Commits", item.count)
                    )
                    .foregroundStyle(.purple.gradient)
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .weekOfYear, count: 4)) { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.month().day())
                    }
                }
                .padding()
                .background(Color.goalCardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var repositoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Repositories")
                    .font(.headline)

                Spacer()

                Button {
                    Task {
                        await syncAllRepositories()
                    }
                } label: {
                    Label("Sync All", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .disabled(isLoading)
            }

            if goal.sortedRepositories.isEmpty {
                ContentUnavailableView {
                    Label("No Repositories", systemImage: "folder")
                } description: {
                    Text("Add repositories to track your commits")
                } actions: {
                    Button("Add Repository") {
                        showingAddRepo = true
                    }
                }
                .frame(height: 200)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(goal.sortedRepositories) { repo in
                        RepositoryRow(repository: repo) {
                            deleteRepository(repo)
                        } onSync: {
                            Task {
                                await syncRepository(repo)
                            }
                        }
                    }
                }
            }
        }
    }

    private func connectGitHub() {
        // Get credentials from user defaults or settings
        let clientId = UserDefaults.standard.string(forKey: "github_client_id") ?? ""
        let clientSecret = UserDefaults.standard.string(forKey: "github_client_secret") ?? ""

        Task {
            do {
                try await authService.authenticate(clientId: clientId, clientSecret: clientSecret)
            } catch {
                self.error = error.localizedDescription
            }
        }
    }

    private func syncRepository(_ repo: GitHubRepository) async {
        guard let token = authService.getAccessToken() else { return }

        do {
            let repoData = try await apiService.fetchRepository(
                owner: repo.ownerName,
                repo: repo.repoName,
                token: token
            )

            await MainActor.run {
                repo.updateFromAPI(
                    description: repoData.description,
                    language: repoData.language,
                    stars: repoData.stargazersCount,
                    forks: repoData.forksCount,
                    issues: repoData.openIssuesCount,
                    isPrivate: repoData.isPrivate
                )
            }

            let activities = try await apiService.fetchCommitActivity(
                owner: repo.ownerName,
                repo: repo.repoName,
                token: token
            )

            await MainActor.run {
                // Clear old activities
                for activity in repo.commitActivities ?? [] {
                    modelContext.delete(activity)
                }

                // Add new activities
                for week in activities where week.count > 0 {
                    let activity = CommitActivity(
                        weekStartDate: week.weekStart,
                        commitCount: week.count
                    )
                    modelContext.insert(activity)
                    activity.repository = repo
                }

                goal.updateProgress()
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
            }
        }
    }

    private func syncAllRepositories() async {
        isLoading = true
        defer { Task { @MainActor in isLoading = false } }

        for repo in goal.sortedRepositories {
            await syncRepository(repo)
        }
    }

    private func deleteRepository(_ repo: GitHubRepository) {
        modelContext.delete(repo)
        goal.updateProgress()
    }
}

struct RepositoryRow: View {
    let repository: GitHubRepository
    let onDelete: () -> Void
    let onSync: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(repository.name)
                        .font(.system(.body, weight: .medium))

                    if repository.isPrivate {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Text(repository.fullName)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let description = repository.repoDescription {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            HStack(spacing: 16) {
                if let language = repository.language {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.forLanguage(language))
                            .frame(width: 8, height: 8)
                        Text(language)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Label("\(repository.starCount)", systemImage: "star")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(repository.totalCommits)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text("commits")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Menu {
                Button("Sync", action: onSync)

                if let url = URL(string: repository.htmlURL) {
                    Link("Open in Browser", destination: url)
                }

                Divider()

                Button("Remove", role: .destructive, action: onDelete)
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color.goalCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - App Revenue Row

struct AppRevenueRow: View {
    let project: AppProject
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                AppIconView(iconURL: project.iconURL, platform: project.platform, size: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(project.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)

                    Text(project.platform.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(project.formattedTotalRevenue)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(.green)

                    if let growth = project.revenueGrowthPercentage {
                        HStack(spacing: 2) {
                            Image(systemName: growth >= 0 ? "arrow.up" : "arrow.down")
                                .font(.caption2)
                            Text(String(format: "%.0f%%", abs(growth)))
                        }
                        .font(.caption)
                        .foregroundStyle(growth >= 0 ? .green : .red)
                    } else {
                        Text("total")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Goal.self, configurations: config)

    let goal = Goal(title: "1000 Commits", goalType: .programming, targetValue: 1000)
    container.mainContext.insert(goal)

    return ProgrammingGoalDetailView(goal: goal)
        .modelContainer(container)
        .frame(width: 800, height: 700)
}
