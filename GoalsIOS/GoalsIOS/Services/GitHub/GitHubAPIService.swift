import Foundation

enum GitHubAPIError: Error, LocalizedError {
    case notAuthenticated
    case rateLimited
    case notFound
    case networkError(Error)
    case decodingError

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Not authenticated with GitHub"
        case .rateLimited:
            return "GitHub API rate limit exceeded"
        case .notFound:
            return "Repository not found"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError:
            return "Failed to parse GitHub response"
        }
    }
}

struct GitHubRepoResponse: Codable, Identifiable {
    let id: Int
    let name: String
    let fullName: String
    let description: String?
    let htmlURL: String
    let language: String?
    let stargazersCount: Int
    let forksCount: Int
    let openIssuesCount: Int
    let isPrivate: Bool
    let defaultBranch: String

    enum CodingKeys: String, CodingKey {
        case id, name, description, language
        case fullName = "full_name"
        case htmlURL = "html_url"
        case stargazersCount = "stargazers_count"
        case forksCount = "forks_count"
        case openIssuesCount = "open_issues_count"
        case isPrivate = "private"
        case defaultBranch = "default_branch"
    }
}

struct CommitWeek: Identifiable {
    let id = UUID()
    let weekStart: Date
    let count: Int
}

struct ParticipationResponse: Codable {
    let all: [Int]
    let owner: [Int]
}

struct ContributorStats: Codable {
    let total: Int
    let weeks: [WeekStats]

    struct WeekStats: Codable {
        let w: Int  // Unix timestamp
        let a: Int  // additions
        let d: Int  // deletions
        let c: Int  // commits
    }
}

actor GitHubAPIService {
    private let session: URLSession
    private let baseURL = Constants.API.githubBaseURL

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchUserRepositories(token: String) async throws -> [GitHubRepoResponse] {
        var request = URLRequest(url: URL(string: "\(baseURL)/user/repos?per_page=100&sort=updated&type=owner")!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)

        try checkResponse(response)

        return try JSONDecoder().decode([GitHubRepoResponse].self, from: data)
    }

    func fetchRepository(owner: String, repo: String, token: String) async throws -> GitHubRepoResponse {
        var request = URLRequest(url: URL(string: "\(baseURL)/repos/\(owner)/\(repo)")!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)

        try checkResponse(response)

        return try JSONDecoder().decode(GitHubRepoResponse.self, from: data)
    }

    func fetchCommitActivity(owner: String, repo: String, token: String, retryCount: Int = 0) async throws -> [CommitWeek] {
        var request = URLRequest(url: URL(string: "\(baseURL)/repos/\(owner)/\(repo)/stats/participation")!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GitHubAPIError.networkError(NSError(domain: "", code: -1))
        }

        // GitHub returns 202 if stats are being computed
        if httpResponse.statusCode == 202 && retryCount < 3 {
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            return try await fetchCommitActivity(owner: owner, repo: repo, token: token, retryCount: retryCount + 1)
        }

        try checkResponse(response)

        let participation = try JSONDecoder().decode(ParticipationResponse.self, from: data)
        return mapToCommitWeeks(participation.owner)
    }

    func fetchContributorStats(owner: String, repo: String, token: String, retryCount: Int = 0) async throws -> [ContributorStats] {
        var request = URLRequest(url: URL(string: "\(baseURL)/repos/\(owner)/\(repo)/stats/contributors")!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GitHubAPIError.networkError(NSError(domain: "", code: -1))
        }

        if httpResponse.statusCode == 202 && retryCount < 3 {
            try await Task.sleep(nanoseconds: 2_000_000_000)
            return try await fetchContributorStats(owner: owner, repo: repo, token: token, retryCount: retryCount + 1)
        }

        try checkResponse(response)

        return try JSONDecoder().decode([ContributorStats].self, from: data)
    }

    func searchRepositories(query: String, token: String) async throws -> [GitHubRepoResponse] {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        var request = URLRequest(url: URL(string: "\(baseURL)/search/repositories?q=\(encoded)&per_page=20")!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)

        try checkResponse(response)

        struct SearchResponse: Codable {
            let items: [GitHubRepoResponse]
        }

        let searchResponse = try JSONDecoder().decode(SearchResponse.self, from: data)
        return searchResponse.items
    }

    private func checkResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GitHubAPIError.networkError(NSError(domain: "", code: -1))
        }

        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401:
            throw GitHubAPIError.notAuthenticated
        case 403:
            throw GitHubAPIError.rateLimited
        case 404:
            throw GitHubAPIError.notFound
        default:
            throw GitHubAPIError.networkError(NSError(domain: "", code: httpResponse.statusCode))
        }
    }

    private func mapToCommitWeeks(_ counts: [Int]) -> [CommitWeek] {
        let calendar = Calendar.current
        let now = Date()

        return counts.enumerated().map { index, count in
            let weekOffset = counts.count - 1 - index
            let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: now) ?? now
            return CommitWeek(weekStart: weekStart, count: count)
        }
    }
}
