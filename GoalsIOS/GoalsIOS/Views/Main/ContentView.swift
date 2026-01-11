import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            OverviewView()
                .tabItem {
                    Label("Overview", systemImage: "chart.pie.fill")
                }

            GoalListView(goalType: .bookReading)
                .tabItem {
                    Label("Books", systemImage: "book.fill")
                }

            GoalListView(goalType: .fitness)
                .tabItem {
                    Label("Fitness", systemImage: "figure.run")
                }

            GoalListView(goalType: .programming)
                .tabItem {
                    Label("Code", systemImage: "chevron.left.forwardslash.chevron.right")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Goal.self, inMemory: true)
}
