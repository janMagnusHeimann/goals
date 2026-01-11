import SwiftUI
import SwiftData

@main
struct GoalsApp: App {
    let container: ModelContainer

    init() {
        let schema = Schema([
            Goal.self,
            Book.self,
            Chapter.self,
            ChapterNote.self,
            TrainingSession.self,
            GitHubRepository.self,
            CommitActivity.self
        ])

        // Using local-only storage (no CloudKit)
        // To enable CloudKit sync later, add an Apple Developer account and configure iCloud
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            container = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
        } catch {
            fatalError("Failed to configure SwiftData container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Goal") {
                    NotificationCenter.default.post(name: .newGoalRequested, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }

        #if os(macOS)
        Settings {
            SettingsView()
        }
        .modelContainer(container)
        #endif
    }
}

extension Notification.Name {
    static let newGoalRequested = Notification.Name("newGoalRequested")
}
