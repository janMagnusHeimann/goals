import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            APIKeysSettingsView()
                .tabItem {
                    Label("API Keys", systemImage: "key.fill")
                }

            GitHubSettingsView()
                .tabItem {
                    Label("GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
                }

            AboutSettingsView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 550, height: 400)
    }
}

struct GeneralSettingsView: View {
    @AppStorage("showCompletedGoals") private var showCompletedGoals = true
    @AppStorage("defaultGoalType") private var defaultGoalType = "book_reading"
    @AppStorage("enableNotifications") private var enableNotifications = true

    var body: some View {
        Form {
            Section {
                Toggle("Show completed goals in sidebar", isOn: $showCompletedGoals)

                Picker("Default goal type", selection: $defaultGoalType) {
                    ForEach(GoalType.allCases) { type in
                        Text(type.displayName).tag(type.rawValue)
                    }
                }

                Toggle("Enable notifications", isOn: $enableNotifications)
            }

            Section {
                Text("Data is synced via iCloud to all your devices.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

struct APIKeysSettingsView: View {
    @State private var anthropicKey: String = ""
    @State private var showAnthropicKey = false
    @State private var anthropicKeySaved = false

    private let keychainManager = KeychainManager.shared

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Anthropic API Key")
                        .font(.headline)

                    Text("Used for AI-powered goal structuring and suggestions")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack {
                        if showAnthropicKey {
                            TextField("sk-ant-...", text: $anthropicKey)
                                .textFieldStyle(.roundedBorder)
                        } else {
                            SecureField("sk-ant-...", text: $anthropicKey)
                                .textFieldStyle(.roundedBorder)
                        }

                        Button {
                            showAnthropicKey.toggle()
                        } label: {
                            Image(systemName: showAnthropicKey ? "eye.slash" : "eye")
                        }
                        .buttonStyle(.borderless)
                    }

                    HStack {
                        Button("Save") {
                            saveAnthropicKey()
                        }
                        .disabled(anthropicKey.isEmpty)

                        if anthropicKeySaved {
                            Label("Saved", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }

                        Spacer()

                        if keychainManager.exists(.anthropicAPIKey) {
                            Button("Clear", role: .destructive) {
                                clearAnthropicKey()
                            }
                            .buttonStyle(.borderless)
                        }
                    }

                    Link("Get an API key from Anthropic Console",
                         destination: URL(string: "https://console.anthropic.com/settings/keys")!)
                        .font(.caption)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            loadKeys()
        }
    }

    private func loadKeys() {
        if let key = keychainManager.get(.anthropicAPIKey) {
            anthropicKey = key
        }
    }

    private func saveAnthropicKey() {
        _ = keychainManager.save(anthropicKey, forKey: .anthropicAPIKey)
        anthropicKeySaved = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            anthropicKeySaved = false
        }
    }

    private func clearAnthropicKey() {
        _ = keychainManager.delete(.anthropicAPIKey)
        anthropicKey = ""
    }
}

struct GitHubSettingsView: View {
    @StateObject private var authService = GitHubAuthService()
    @AppStorage("github_client_id") private var clientId = ""
    @AppStorage("github_client_secret") private var clientSecret = ""
    @State private var showClientSecret = false
    @State private var isConnecting = false
    @State private var error: String?

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    Text("GitHub OAuth Credentials")
                        .font(.headline)

                    Text("Create an OAuth App at GitHub Developer Settings to enable GitHub integration.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Client ID")
                            .font(.subheadline)
                        TextField("Client ID", text: $clientId)
                            .textFieldStyle(.roundedBorder)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Client Secret")
                            .font(.subheadline)
                        HStack {
                            if showClientSecret {
                                TextField("Client Secret", text: $clientSecret)
                                    .textFieldStyle(.roundedBorder)
                            } else {
                                SecureField("Client Secret", text: $clientSecret)
                                    .textFieldStyle(.roundedBorder)
                            }

                            Button {
                                showClientSecret.toggle()
                            } label: {
                                Image(systemName: showClientSecret ? "eye.slash" : "eye")
                            }
                            .buttonStyle(.borderless)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Callback URL (use this when creating the OAuth App):")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack {
                            Text("goals://github/callback")
                                .font(.system(.caption, design: .monospaced))
                                .padding(6)
                                .background(Color.secondary.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 4))

                            Button {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString("goals://github/callback", forType: .string)
                            } label: {
                                Image(systemName: "doc.on.doc")
                            }
                            .buttonStyle(.borderless)
                        }
                    }

                    Link("Create GitHub OAuth App",
                         destination: URL(string: "https://github.com/settings/developers")!)
                        .font(.caption)
                }
            }

            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Connection Status")
                        .font(.headline)

                    if authService.isAuthenticated {
                        HStack(spacing: 12) {
                            if let user = authService.user {
                                AsyncImage(url: URL(string: user.avatarURL)) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Circle()
                                        .fill(Color.secondary.opacity(0.2))
                                }
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())

                                VStack(alignment: .leading) {
                                    Text(user.name ?? user.login)
                                        .fontWeight(.medium)
                                    Text("@\(user.login)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()

                            Label("Connected", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }

                        Button("Disconnect") {
                            authService.signOut()
                        }
                        .buttonStyle(.borderless)
                        .foregroundStyle(.red)
                    } else {
                        HStack {
                            Label("Not connected", systemImage: "xmark.circle")
                                .foregroundStyle(.secondary)

                            Spacer()

                            Button("Connect GitHub") {
                                connectGitHub()
                            }
                            .disabled(clientId.isEmpty || clientSecret.isEmpty || isConnecting)

                            if isConnecting {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }

                        if let error = error {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func connectGitHub() {
        isConnecting = true
        error = nil

        Task {
            do {
                try await authService.authenticate(clientId: clientId, clientSecret: clientSecret)
                await MainActor.run {
                    isConnecting = false
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    isConnecting = false
                }
            }
        }
    }
}

struct AboutSettingsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "target")
                .font(.system(size: 64))
                .foregroundStyle(.blue)

            Text("Goals")
                .font(.title)
                .fontWeight(.bold)

            Text("Track your goals with style")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("Version 1.0.0")
                .font(.caption)
                .foregroundStyle(.tertiary)

            Divider()
                .frame(width: 200)

            VStack(spacing: 8) {
                Text("Built with SwiftUI & SwiftData")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("Powered by Claude AI")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    SettingsView()
}
