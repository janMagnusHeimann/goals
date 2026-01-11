import SwiftUI

struct AddRepositorySheet: View {
    @Environment(\.dismiss) private var dismiss
    let goal: Goal
    let authService: GitHubAuthService
    let onAdd: (GitHubRepository) -> Void

    @State private var searchQuery = ""
    @State private var userRepos: [GitHubRepoResponse] = []
    @State private var searchResults: [GitHubRepoResponse] = []
    @State private var isLoading = false
    @State private var error: String?
    @State private var selectedTab = 0

    private let apiService = GitHubAPIService()

    private var existingRepoIds: Set<Int> {
        Set((goal.repositories ?? []).map { $0.repoId })
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()

            TabView(selection: $selectedTab) {
                myReposTab
                    .tabItem { Label("My Repos", systemImage: "folder") }
                    .tag(0)

                searchTab
                    .tabItem { Label("Search", systemImage: "magnifyingglass") }
                    .tag(1)

                urlTab
                    .tabItem { Label("URL", systemImage: "link") }
                    .tag(2)
            }
            .padding()
        }
        .frame(width: 600, height: 500)
        .onAppear {
            loadUserRepos()
        }
    }

    private var header: some View {
        HStack {
            Text("Add Repository")
                .font(.title2)
                .fontWeight(.semibold)

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(20)
    }

    private var myReposTab: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Your Repositories")
                    .font(.headline)

                Spacer()

                Button {
                    loadUserRepos()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .disabled(isLoading)
            }

            if isLoading && userRepos.isEmpty {
                Spacer()
                ProgressView("Loading repositories...")
                Spacer()
            } else if userRepos.isEmpty {
                Spacer()
                ContentUnavailableView {
                    Label("No Repositories", systemImage: "folder")
                } description: {
                    Text("You don't have any repositories yet")
                }
                Spacer()
            } else {
                List(userRepos.filter { !existingRepoIds.contains($0.id) }) { repo in
                    RepoSelectRow(repo: repo) {
                        addRepository(repo)
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    private var searchTab: some View {
        VStack(spacing: 16) {
            HStack {
                TextField("Search GitHub repositories...", text: $searchQuery)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        searchRepos()
                    }

                Button("Search") {
                    searchRepos()
                }
                .disabled(searchQuery.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
            }

            if isLoading && searchResults.isEmpty {
                Spacer()
                ProgressView("Searching...")
                Spacer()
            } else if searchResults.isEmpty && !searchQuery.isEmpty {
                Spacer()
                ContentUnavailableView {
                    Label("No Results", systemImage: "magnifyingglass")
                } description: {
                    Text("No repositories found for '\(searchQuery)'")
                }
                Spacer()
            } else if searchResults.isEmpty {
                Spacer()
                ContentUnavailableView {
                    Label("Search Repositories", systemImage: "magnifyingglass")
                } description: {
                    Text("Enter a repository name or owner/repo to search")
                }
                Spacer()
            } else {
                List(searchResults.filter { !existingRepoIds.contains($0.id) }) { repo in
                    RepoSelectRow(repo: repo) {
                        addRepository(repo)
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    @State private var repoURL = ""

    private var urlTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Add by URL")
                .font(.headline)

            TextField("https://github.com/owner/repo", text: $repoURL)
                .textFieldStyle(.roundedBorder)

            Text("Paste a GitHub repository URL to add it directly")
                .font(.caption)
                .foregroundStyle(.secondary)

            if let error = error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Spacer()

            HStack {
                Spacer()
                Button("Add Repository") {
                    addRepoFromURL()
                }
                .buttonStyle(.borderedProminent)
                .disabled(repoURL.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
            }
        }
    }

    private func loadUserRepos() {
        guard let token = authService.getAccessToken() else { return }

        isLoading = true
        error = nil

        Task {
            do {
                let repos = try await apiService.fetchUserRepositories(token: token)
                await MainActor.run {
                    userRepos = repos
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }

    private func searchRepos() {
        guard let token = authService.getAccessToken() else { return }
        let query = searchQuery.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return }

        isLoading = true
        error = nil

        Task {
            do {
                let repos = try await apiService.searchRepositories(query: query, token: token)
                await MainActor.run {
                    searchResults = repos
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }

    private func addRepoFromURL() {
        guard let token = authService.getAccessToken() else { return }

        // Parse URL like https://github.com/owner/repo
        let url = repoURL.trimmingCharacters(in: .whitespaces)
        let components = url
            .replacingOccurrences(of: "https://github.com/", with: "")
            .replacingOccurrences(of: "http://github.com/", with: "")
            .split(separator: "/")

        guard components.count >= 2 else {
            error = "Invalid GitHub URL. Use format: https://github.com/owner/repo"
            return
        }

        let owner = String(components[0])
        let repo = String(components[1]).replacingOccurrences(of: ".git", with: "")

        isLoading = true
        error = nil

        Task {
            do {
                let repoData = try await apiService.fetchRepository(owner: owner, repo: repo, token: token)
                await MainActor.run {
                    addRepository(repoData)
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }

    private func addRepository(_ repoData: GitHubRepoResponse) {
        let repo = GitHubRepository(
            repoId: repoData.id,
            name: repoData.name,
            fullName: repoData.fullName,
            htmlURL: repoData.htmlURL
        )
        repo.repoDescription = repoData.description
        repo.language = repoData.language
        repo.starCount = repoData.stargazersCount
        repo.forkCount = repoData.forksCount
        repo.openIssuesCount = repoData.openIssuesCount
        repo.isPrivate = repoData.isPrivate
        repo.defaultBranch = repoData.defaultBranch

        onAdd(repo)
        dismiss()
    }
}

struct RepoSelectRow: View {
    let repo: GitHubRepoResponse
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(repo.name)
                            .font(.system(.body, weight: .medium))
                            .foregroundStyle(.primary)

                        if repo.isPrivate {
                            Image(systemName: "lock.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Text(repo.fullName)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let description = repo.description {
                        Text(description)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                HStack(spacing: 12) {
                    if let language = repo.language {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.forLanguage(language))
                                .frame(width: 8, height: 8)
                            Text(language)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Label("\(repo.stargazersCount)", systemImage: "star")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.purple)
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AddRepositorySheet(
        goal: Goal(title: "Test", goalType: .programming, targetValue: 100),
        authService: GitHubAuthService()
    ) { _ in }
}
