import Foundation
import AuthenticationServices
import SwiftUI

enum GitHubAuthError: Error, LocalizedError {
    case invalidCallback
    case tokenExchangeFailed
    case cancelled
    case missingCredentials
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidCallback:
            return "Invalid callback from GitHub"
        case .tokenExchangeFailed:
            return "Failed to exchange code for token"
        case .cancelled:
            return "Authentication was cancelled"
        case .missingCredentials:
            return "GitHub client credentials not configured"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

struct GitHubUser: Codable {
    let id: Int
    let login: String
    let avatarURL: String
    let name: String?
    let publicRepos: Int
    let followers: Int
    let following: Int

    enum CodingKeys: String, CodingKey {
        case id, login, name, followers, following
        case avatarURL = "avatar_url"
        case publicRepos = "public_repos"
    }
}

@MainActor
class GitHubAuthService: NSObject, ObservableObject {
    @Published var isAuthenticated = false
    @Published var user: GitHubUser?
    @Published var isLoading = false
    @Published var error: String?

    private var authSession: ASWebAuthenticationSession?
    private let keychainManager = KeychainManager.shared

    override init() {
        super.init()
        checkExistingAuth()
    }

    private func checkExistingAuth() {
        if let token = keychainManager.get(.githubAccessToken) {
            isAuthenticated = true
            Task {
                await fetchUser(token: token)
            }
        }
    }

    func authenticate(clientId: String, clientSecret: String) async throws {
        guard !clientId.isEmpty, !clientSecret.isEmpty else {
            throw GitHubAuthError.missingCredentials
        }

        isLoading = true
        error = nil

        defer { isLoading = false }

        let authURL = buildAuthURL(clientId: clientId)

        let code = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            authSession = ASWebAuthenticationSession(
                url: authURL,
                callbackURLScheme: Constants.App.urlScheme
            ) { callbackURL, error in
                if let error = error {
                    if (error as NSError).code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                        continuation.resume(throwing: GitHubAuthError.cancelled)
                    } else {
                        continuation.resume(throwing: GitHubAuthError.networkError(error))
                    }
                    return
                }

                guard let callbackURL = callbackURL,
                      let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
                      let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
                    continuation.resume(throwing: GitHubAuthError.invalidCallback)
                    return
                }

                continuation.resume(returning: code)
            }

            authSession?.presentationContextProvider = self
            authSession?.prefersEphemeralWebBrowserSession = false
            authSession?.start()
        }

        try await exchangeCodeForToken(code, clientId: clientId, clientSecret: clientSecret)
    }

    func signOut() {
        _ = keychainManager.delete(.githubAccessToken)
        _ = keychainManager.delete(.githubRefreshToken)
        isAuthenticated = false
        user = nil
    }

    func getAccessToken() -> String? {
        keychainManager.get(.githubAccessToken)
    }

    private func buildAuthURL(clientId: String) -> URL {
        var components = URLComponents(string: Constants.API.githubAuthURL)!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: Constants.GitHub.redirectURI),
            URLQueryItem(name: "scope", value: Constants.GitHub.scopes),
            URLQueryItem(name: "state", value: UUID().uuidString)
        ]
        return components.url!
    }

    private func exchangeCodeForToken(_ code: String, clientId: String, clientSecret: String) async throws {
        var request = URLRequest(url: URL(string: Constants.API.githubTokenURL)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "client_id": clientId,
            "client_secret": clientSecret,
            "code": code,
            "redirect_uri": Constants.GitHub.redirectURI
        ]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw GitHubAuthError.tokenExchangeFailed
        }

        struct TokenResponse: Codable {
            let access_token: String
            let token_type: String
            let scope: String
        }

        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
        _ = keychainManager.save(tokenResponse.access_token, forKey: .githubAccessToken)

        isAuthenticated = true
        await fetchUser(token: tokenResponse.access_token)
    }

    private func fetchUser(token: String) async {
        var request = URLRequest(url: URL(string: "\(Constants.API.githubBaseURL)/user")!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            self.user = try JSONDecoder().decode(GitHubUser.self, from: data)
        } catch {
            print("Failed to fetch user: \(error)")
            self.error = error.localizedDescription
        }
    }
}

extension GitHubAuthService: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        NSApplication.shared.keyWindow ?? ASPresentationAnchor()
    }
}
