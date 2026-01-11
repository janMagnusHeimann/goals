import SwiftUI

struct AddAppProjectSheet: View {
    @Environment(\.dismiss) private var dismiss

    let goal: Goal
    let onSave: (AppProject) -> Void

    @State private var name: String = ""
    @State private var platform: AppPlatform = .iOS
    @State private var appStoreId: String = ""
    @State private var bundleId: String = ""
    @State private var appDescription: String = ""
    @State private var websiteURL: String = ""
    @State private var launchDate: Date = Date()
    @State private var hasLaunched: Bool = false
    @State private var currentVersion: String = ""

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("New App Project")
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
            .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // App Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("App Name")
                            .font(.headline)
                        TextField("My Awesome App", text: $name)
                            .textFieldStyle(.roundedBorder)
                    }

                    // Platform
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Platform")
                            .font(.headline)

                        Picker("Platform", selection: $platform) {
                            ForEach(AppPlatform.allCases) { platform in
                                Label(platform.displayName, systemImage: platform.icon)
                                    .tag(platform)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    // Store ID (based on platform)
                    if platform == .iOS || platform == .macOS {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("App Store ID")
                                .font(.headline)
                            TextField("e.g., 1234567890", text: $appStoreId)
                                .textFieldStyle(.roundedBorder)
                            Text("Found in your app's App Store URL")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else if platform == .android {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Bundle ID")
                                .font(.headline)
                            TextField("e.g., com.yourcompany.app", text: $bundleId)
                                .textFieldStyle(.roundedBorder)
                        }
                    }

                    // Launch Status
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Already Launched", isOn: $hasLaunched)
                            .font(.headline)

                        if hasLaunched {
                            DatePicker(
                                "Launch Date",
                                selection: $launchDate,
                                displayedComponents: .date
                            )
                        }
                    }

                    // Current Version
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Current Version")
                            .font(.headline)
                        TextField("e.g., 1.0.0", text: $currentVersion)
                            .textFieldStyle(.roundedBorder)
                    }

                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description (optional)")
                            .font(.headline)
                        TextField("Brief description of your app", text: $appDescription, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(2...4)
                    }

                    // Website
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Website URL (optional)")
                            .font(.headline)
                        TextField("https://yourapp.com", text: $websiteURL)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                .padding()
            }

            Divider()

            // Footer
            HStack {
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape)

                Button("Add Project") {
                    saveProject()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isValid)
                .keyboardShortcut(.return)
            }
            .padding()
        }
        .frame(width: 450, height: 600)
    }

    private func saveProject() {
        let project = AppProject(
            name: name.trimmingCharacters(in: .whitespaces),
            platform: platform,
            appStoreId: appStoreId.isEmpty ? nil : appStoreId,
            launchDate: hasLaunched ? launchDate : nil
        )

        project.bundleId = bundleId.isEmpty ? nil : bundleId
        project.appDescription = appDescription.isEmpty ? nil : appDescription
        project.websiteURL = websiteURL.isEmpty ? nil : websiteURL
        project.currentVersion = currentVersion.isEmpty ? nil : currentVersion
        project.goal = goal

        onSave(project)
        dismiss()
    }
}

// MARK: - Edit App Project Sheet

struct EditAppProjectSheet: View {
    @Environment(\.dismiss) private var dismiss

    let project: AppProject
    let onSave: () -> Void
    let onDelete: (() -> Void)?

    @State private var name: String = ""
    @State private var platform: AppPlatform = .iOS
    @State private var appStoreId: String = ""
    @State private var bundleId: String = ""
    @State private var appDescription: String = ""
    @State private var websiteURL: String = ""
    @State private var launchDate: Date = Date()
    @State private var hasLaunched: Bool = false
    @State private var currentVersion: String = ""
    @State private var showDeleteConfirmation: Bool = false

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Edit App Project")
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
            .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Same fields as Add sheet
                    VStack(alignment: .leading, spacing: 8) {
                        Text("App Name")
                            .font(.headline)
                        TextField("My Awesome App", text: $name)
                            .textFieldStyle(.roundedBorder)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Platform")
                            .font(.headline)
                        Picker("Platform", selection: $platform) {
                            ForEach(AppPlatform.allCases) { platform in
                                Label(platform.displayName, systemImage: platform.icon)
                                    .tag(platform)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    if platform == .iOS || platform == .macOS {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("App Store ID")
                                .font(.headline)
                            TextField("e.g., 1234567890", text: $appStoreId)
                                .textFieldStyle(.roundedBorder)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Already Launched", isOn: $hasLaunched)
                            .font(.headline)
                        if hasLaunched {
                            DatePicker("Launch Date", selection: $launchDate, displayedComponents: .date)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Current Version")
                            .font(.headline)
                        TextField("e.g., 1.0.0", text: $currentVersion)
                            .textFieldStyle(.roundedBorder)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description (optional)")
                            .font(.headline)
                        TextField("Brief description", text: $appDescription, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(2...4)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Website URL (optional)")
                            .font(.headline)
                        TextField("https://yourapp.com", text: $websiteURL)
                            .textFieldStyle(.roundedBorder)
                    }

                    // Delete button
                    if onDelete != nil {
                        Divider()
                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete Project", systemImage: "trash")
                        }
                    }
                }
                .padding()
            }

            Divider()

            HStack {
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape)

                Button("Save Changes") {
                    saveChanges()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isValid)
                .keyboardShortcut(.return)
            }
            .padding()
        }
        .frame(width: 450, height: 600)
        .onAppear {
            loadProjectData()
        }
        .confirmationDialog(
            "Delete Project",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                onDelete?()
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete \"\(project.name)\"? This will also delete all revenue data.")
        }
    }

    private func loadProjectData() {
        name = project.name
        platform = project.platform
        appStoreId = project.appStoreId ?? ""
        bundleId = project.bundleId ?? ""
        appDescription = project.appDescription ?? ""
        websiteURL = project.websiteURL ?? ""
        currentVersion = project.currentVersion ?? ""
        hasLaunched = project.launchDate != nil
        launchDate = project.launchDate ?? Date()
    }

    private func saveChanges() {
        project.name = name.trimmingCharacters(in: .whitespaces)
        project.platform = platform
        project.appStoreId = appStoreId.isEmpty ? nil : appStoreId
        project.bundleId = bundleId.isEmpty ? nil : bundleId
        project.appDescription = appDescription.isEmpty ? nil : appDescription
        project.websiteURL = websiteURL.isEmpty ? nil : websiteURL
        project.currentVersion = currentVersion.isEmpty ? nil : currentVersion
        project.launchDate = hasLaunched ? launchDate : nil

        onSave()
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    let goal = Goal(title: "Programming 2026", goalType: .programming, targetValue: 100)

    return AddAppProjectSheet(goal: goal) { project in
        print("Added project: \(project.name)")
    }
}
