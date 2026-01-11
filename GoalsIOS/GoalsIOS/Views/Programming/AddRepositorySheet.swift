import SwiftUI
import SwiftData

struct AddRepositorySheet: View {
    let goal: Goal
    let authService: GitHubAuthService

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var repositories: [GitHubRepoResponse] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var searchQuery = ""

    private let apiService = GitHubAPIService()

    private var filteredRepositories: [GitHubRepoResponse] {
        if searchQuery.isEmpty {
            return repositories
        }
        return repositories.filter {
            $0.fullName.localizedCaseInsensitiveContains(searchQuery)
        }
    }

    private var linkedRepoIds: Set<Int> {
        Set(goal.sortedRepositories.map { $0.repoId })
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading repositories...")
                } else if let error = errorMessage {
                    ContentUnavailableView {
                        Label("Error", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(error)
                    } actions: {
                        Button("Retry") {
                            Task { await loadRepositories() }
                        }
                    }
                } else {
                    List {
                        ForEach(filteredRepositories) { repo in
                            let isLinked = linkedRepoIds.contains(repo.id)

                            Button {
                                if !isLinked {
                                    addRepository(repo)
                                }
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(repo.fullName)
                                            .font(.headline)

                                        HStack(spacing: 12) {
                                            if let language = repo.language {
                                                HStack(spacing: 4) {
                                                    Circle()
                                                        .fill(Color.forLanguage(language))
                                                        .frame(width: 8, height: 8)
                                                    Text(language)
                                                        .font(.caption)
                                                }
                                            }

                                            Label("\(repo.stargazersCount)", systemImage: "star")
                                                .font(.caption)
                                        }
                                        .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    if isLinked {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                    } else {
                                        Image(systemName: "plus.circle")
                                            .foregroundStyle(.blue)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .disabled(isLinked)
                        }
                    }
                    .searchable(text: $searchQuery, prompt: "Filter repositories")
                }
            }
            .navigationTitle("Add Repository")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadRepositories()
            }
        }
    }

    private func loadRepositories() async {
        guard let token = authService.getAccessToken() else {
            errorMessage = "Not authenticated"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            repositories = try await apiService.fetchUserRepositories(token: token)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func addRepository(_ repo: GitHubRepoResponse) {
        let repository = GitHubRepository(
            repoId: repo.id,
            name: repo.name,
            fullName: repo.fullName,
            htmlURL: repo.htmlURL
        )

        repository.repoDescription = repo.description
        repository.language = repo.language
        repository.starCount = repo.stargazersCount
        repository.forkCount = repo.forksCount
        repository.openIssuesCount = repo.openIssuesCount
        repository.isPrivate = repo.isPrivate
        repository.defaultBranch = repo.defaultBranch
        repository.goal = goal

        modelContext.insert(repository)

        // Fetch commit stats in background
        Task {
            await fetchCommitStats(for: repository)
        }

        goal.updateProgress()
    }

    private func fetchCommitStats(for repository: GitHubRepository) async {
        guard let token = authService.getAccessToken() else { return }

        do {
            let commitWeeks = try await apiService.fetchCommitActivity(
                owner: repository.ownerName,
                repo: repository.repoName,
                token: token
            )

            await MainActor.run {
                for week in commitWeeks {
                    let activity = CommitActivity(
                        weekStartDate: week.weekStart,
                        commitCount: week.count
                    )
                    activity.repository = repository
                    modelContext.insert(activity)
                }
                repository.lastSyncedAt = Date()
                goal.updateProgress()
            }
        } catch {
            print("Failed to fetch commit stats: \(error)")
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Goal.self, configurations: config)
    let goal = Goal(title: "Open Source", goalType: .programming, targetValue: 500)
    container.mainContext.insert(goal)

    return AddRepositorySheet(goal: goal, authService: GitHubAuthService())
        .modelContainer(container)
}
