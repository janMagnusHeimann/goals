import SwiftUI
import SwiftData

enum SidebarSelection: Hashable {
    case overview
    case goal(Goal)
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Goal.createdAt, order: .reverse) private var goals: [Goal]
    @State private var selection: SidebarSelection? = .overview
    @State private var showingNewGoalSheet = false
    @State private var columnVisibility = NavigationSplitViewVisibility.all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(
                goals: goals,
                selection: $selection,
                onAddGoal: { showingNewGoalSheet = true },
                onDeleteGoal: deleteGoal
            )
            .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 320)
        } detail: {
            switch selection {
            case .overview:
                OverviewView()
            case .goal(let goal):
                GoalDetailView(goal: goal)
            case nil:
                EmptyStateView(
                    title: "No Goal Selected",
                    message: "Select a goal from the sidebar or create a new one to get started",
                    systemImage: "target",
                    action: { showingNewGoalSheet = true },
                    actionTitle: "Create Goal"
                )
            }
        }
        .sheet(isPresented: $showingNewGoalSheet) {
            NewGoalSheet { newGoal in
                modelContext.insert(newGoal)
                selection = .goal(newGoal)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .newGoalRequested)) { _ in
            showingNewGoalSheet = true
        }
        .frame(minWidth: 900, minHeight: 600)
    }

    private func deleteGoal(_ goal: Goal) {
        if case .goal(let selectedGoal) = selection, selectedGoal.id == goal.id {
            selection = .overview
        }
        modelContext.delete(goal)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Goal.self, inMemory: true)
}
