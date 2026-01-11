import Foundation

enum Constants {
    enum API {
        static let googleBooksBaseURL = "https://www.googleapis.com/books/v1/volumes"
        static let openLibraryCoversURL = "https://covers.openlibrary.org/b/isbn"
        static let githubBaseURL = "https://api.github.com"
        static let githubAuthURL = "https://github.com/login/oauth/authorize"
        static let githubTokenURL = "https://github.com/login/oauth/access_token"
        static let anthropicBaseURL = "https://api.anthropic.com/v1/messages"
        static let anthropicVersion = "2023-06-01"
    }

    enum GitHub {
        static let clientId = "YOUR_GITHUB_CLIENT_ID"
        static let redirectURI = "goalsios://github/callback"
        static let scopes = "read:user repo"
    }

    enum App {
        static let bundleIdentifier = "com.goals.ios.app"
        static let urlScheme = "goalsios"
    }

    enum Defaults {
        static let booksTarget = 12
        static let fitnessSessionsTarget = 100
        static let commitsTarget = 500
    }
}
