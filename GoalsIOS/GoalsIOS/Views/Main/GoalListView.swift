import SwiftUI
import SwiftData

struct GoalListView: View {
    let goalType: GoalType

    @Environment(\.modelContext) private var modelContext
    @Query private var allGoals: [Goal]
    @State private var showingAddGoal = false

    private var goals: [Goal] {
        allGoals.filter { $0.goalType == goalType && !$0.isArchived }
            .sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        NavigationStack {
            Group {
                if goals.isEmpty {
                    EmptyStateView(
                        title: "No \(goalType.displayName) Goals",
                        message: "Tap + to create your first \(goalType.displayName.lowercased()) goal",
                        systemImage: goalType.icon
                    )
                } else {
                    List {
                        ForEach(goals) { goal in
                            NavigationLink(value: goal) {
                                GoalCard(goal: goal)
                            }
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowSeparator(.hidden)
                        }
                        .onDelete(perform: deleteGoals)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle(goalType.displayName)
            .navigationDestination(for: Goal.self) { goal in
                GoalDetailView(goal: goal)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddGoal = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddGoal) {
                AddGoalSheet(goalType: goalType)
            }
        }
    }

    private func deleteGoals(at offsets: IndexSet) {
        for index in offsets {
            let goal = goals[index]
            modelContext.delete(goal)
        }
    }
}

#Preview {
    GoalListView(goalType: .bookReading)
        .modelContainer(for: Goal.self, inMemory: true)
}
