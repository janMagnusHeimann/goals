import SwiftUI

struct SettingsView: View {
    @StateObject private var githubAuth = GitHubAuthService()

    @State private var anthropicAPIKey = ""
    @State private var githubClientId = ""
    @State private var githubClientSecret = ""
    @State private var showingGitHubError = false
    @State private var gitHubError = ""

    private let keychainManager = KeychainManager.shared

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if githubAuth.isAuthenticated {
                        HStack {
                            if let user = githubAuth.user {
                                AsyncImage(url: URL(string: user.avatarURL)) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Circle()
                                        .fill(Color.gray.opacity(0.3))
                                }
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())

                                VStack(alignment: .leading) {
                                    Text(user.name ?? user.login)
                                        .font(.headline)
                                    Text("@\(user.login)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()

                            Button("Sign Out", role: .destructive) {
                                githubAuth.signOut()
                            }
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            TextField("GitHub Client ID", text: $githubClientId)
                                .textContentType(.username)
                                .autocorrectionDisabled()

                            SecureField("GitHub Client Secret", text: $githubClientSecret)
                        }

                        Button {
                            connectGitHub()
                        } label: {
                            if githubAuth.isLoading {
                                ProgressView()
                            } else {
                                Label("Connect GitHub", systemImage: "link")
                            }
                        }
                        .disabled(githubClientId.isEmpty || githubClientSecret.isEmpty || githubAuth.isLoading)
                    }
                } header: {
                    Text("GitHub")
                } footer: {
                    if !githubAuth.isAuthenticated {
                        Text("Create a GitHub OAuth App at github.com/settings/developers")
                    }
                }

                Section {
                    SecureField("Anthropic API Key", text: $anthropicAPIKey)
                        .textContentType(.password)
                        .autocorrectionDisabled()

                    if !anthropicAPIKey.isEmpty {
                        Button("Save API Key") {
                            saveAnthropicKey()
                        }
                    }
                } header: {
                    Text("AI Integration")
                } footer: {
                    Text("Your API key is stored securely in the Keychain")
                }

                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                loadSavedKeys()
            }
            .alert("GitHub Error", isPresented: $showingGitHubError) {
                Button("OK") { }
            } message: {
                Text(gitHubError)
            }
        }
    }

    private func loadSavedKeys() {
        if let key = keychainManager.get(.anthropicAPIKey) {
            anthropicAPIKey = key
        }
    }

    private func saveAnthropicKey() {
        _ = keychainManager.save(anthropicAPIKey, forKey: .anthropicAPIKey)
    }

    private func connectGitHub() {
        Task {
            do {
                try await githubAuth.authenticate(
                    clientId: githubClientId,
                    clientSecret: githubClientSecret
                )
            } catch {
                gitHubError = error.localizedDescription
                showingGitHubError = true
            }
        }
    }
}

#Preview {
    SettingsView()
}
