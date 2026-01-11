import SwiftUI
import SwiftData

@main
struct GoalsIOSApp: App {
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
    }
}
