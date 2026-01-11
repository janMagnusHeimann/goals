import SwiftUI

struct SidebarView: View {
    let goals: [Goal]
    @Binding var selection: SidebarSelection?
    let onAddGoal: () -> Void
    let onDeleteGoal: (Goal) -> Void

    private var bookGoals: [Goal] {
        goals.filter { $0.goalType == .bookReading && !$0.isArchived && $0.isCurrentYear }
    }

    private var fitnessGoals: [Goal] {
        goals.filter { $0.goalType == .fitness && !$0.isArchived && $0.isCurrentYear }
    }

    private var programmingGoals: [Goal] {
        goals.filter { $0.goalType == .programming && !$0.isArchived && $0.isCurrentYear }
    }

    private var archivedGoals: [Goal] {
        goals.filter { $0.isArchived }
    }

    private var activeGoalsCount: Int {
        bookGoals.count + fitnessGoals.count + programmingGoals.count
    }

    var body: some View {
        List(selection: $selection) {
            // Overview Section
            Section {
                Label {
                    HStack {
                        Text("\(Goal.currentYear) Overview")
                        Spacer()
                        Text("\(activeGoalsCount)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.15))
                            .clipShape(Capsule())
                    }
                } icon: {
                    Image(systemName: "chart.pie.fill")
                        .foregroundStyle(.blue)
                }
                .tag(SidebarSelection.overview)
            }

            if !bookGoals.isEmpty {
                Section {
                    ForEach(bookGoals) { goal in
                        GoalRowView(goal: goal)
                            .tag(SidebarSelection.goal(goal))
                            .contextMenu {
                                goalContextMenu(for: goal)
                            }
                    }
                } header: {
                    SectionHeader(
                        title: "Book Reading",
                        icon: "book.fill",
                        color: .blue,
                        count: bookGoals.count
                    )
                }
            }

            if !fitnessGoals.isEmpty {
                Section {
                    ForEach(fitnessGoals) { goal in
                        GoalRowView(goal: goal)
                            .tag(SidebarSelection.goal(goal))
                            .contextMenu {
                                goalContextMenu(for: goal)
                            }
                    }
                } header: {
                    SectionHeader(
                        title: "Fitness",
                        icon: "figure.run",
                        color: .orange,
                        count: fitnessGoals.count
                    )
                }
            }

            if !programmingGoals.isEmpty {
                Section {
                    ForEach(programmingGoals) { goal in
                        GoalRowView(goal: goal)
                            .tag(SidebarSelection.goal(goal))
                            .contextMenu {
                                goalContextMenu(for: goal)
                            }
                    }
                } header: {
                    SectionHeader(
                        title: "Programming",
                        icon: "chevron.left.forwardslash.chevron.right",
                        color: .purple,
                        count: programmingGoals.count
                    )
                }
            }

            if !archivedGoals.isEmpty {
                Section {
                    ForEach(archivedGoals) { goal in
                        GoalRowView(goal: goal)
                            .tag(SidebarSelection.goal(goal))
                            .opacity(0.6)
                            .contextMenu {
                                goalContextMenu(for: goal)
                            }
                    }
                } header: {
                    SectionHeader(
                        title: "Archived",
                        icon: "archivebox",
                        color: .gray,
                        count: archivedGoals.count
                    )
                }
            }

            if activeGoalsCount == 0 && archivedGoals.isEmpty {
                ContentUnavailableView {
                    Label("No Goals", systemImage: "target")
                } description: {
                    Text("Create your first goal to start tracking your progress")
                } actions: {
                    Button("Create Goal") {
                        onAddGoal()
                    }
                }
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Goals")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: onAddGoal) {
                    Image(systemName: "plus")
                }
                .help("Create new goal")
            }
        }
    }

    @ViewBuilder
    private func goalContextMenu(for goal: Goal) -> some View {
        Button(goal.isArchived ? "Unarchive" : "Archive") {
            goal.isArchived.toggle()
        }

        Divider()

        Button("Delete", role: .destructive) {
            onDeleteGoal(goal)
        }
    }
}

struct SectionHeader: View {
    let title: String
    let icon: String
    let color: Color
    let count: Int

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.caption)

            Text(title)

            Spacer()

            Text("\(count)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.15))
                .clipShape(Capsule())
        }
    }
}

#Preview {
    SidebarView(
        goals: [],
        selection: .constant(.overview),
        onAddGoal: {},
        onDeleteGoal: { _ in }
    )
    .frame(width: 260)
}
