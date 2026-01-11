import SwiftUI
import SwiftData

struct BookGoalDetailView: View {
    @Bindable var goal: Goal

    @Environment(\.modelContext) private var modelContext
    @State private var showingAddBook = false
    @State private var showingLogReading = false

    private var currentlyReadingBook: Book? {
        goal.currentlyReadingBook
    }

    private var allReadingSessions: [ReadingSession] {
        goal.sortedBooks.flatMap { $0.sortedReadingSessions }
    }

    var body: some View {
        List {
            // Progress Section
            Section {
                VStack(spacing: 16) {
                    HStack {
                        ProgressRing(progress: goal.progress, color: .blue)
                            .frame(width: 80, height: 80)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(goal.currentValue) of \(goal.targetValue) books")
                                .font(.title2)
                                .fontWeight(.semibold)

                            Text("\(goal.progressPercentage)% complete")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }
                }
                .padding(.vertical, 8)
            }

            // Currently Reading Section
            if let currentBook = currentlyReadingBook {
                Section("Currently Reading") {
                    CompactCurrentlyReadingCard(
                        book: currentBook,
                        onLogReading: {
                            showingLogReading = true
                        }
                    )
                }
            }

            // Reading Stats Section
            if !allReadingSessions.isEmpty {
                Section("Reading Stats") {
                    ReadingStatsView(
                        sessions: allReadingSessions,
                        books: goal.sortedBooks,
                        compact: true
                    )
                }
            }

            // Books List
            Section("Books") {
                if goal.sortedBooks.isEmpty {
                    Text("No books added yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(goal.sortedBooks) { book in
                        NavigationLink {
                            BookDetailView(book: book)
                        } label: {
                            BookRowView(book: book)
                        }
                    }
                    .onDelete(perform: deleteBooks)
                }
            }
        }
        .navigationTitle(goal.title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddBook = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddBook) {
            AddBookSheet(goal: goal)
        }
        .sheet(isPresented: $showingLogReading) {
            if let book = currentlyReadingBook {
                LogReadingSheet(book: book, onSave: { session in
                    modelContext.insert(session)
                    session.book = book
                    book.currentPage = min(book.currentPage + session.pagesRead, book.totalPages ?? book.currentPage + session.pagesRead)
                    book.lastReadDate = Date()
                })
            }
        }
        .onChange(of: goal.books?.count) {
            goal.updateProgress()
        }
    }

    private func deleteBooks(at offsets: IndexSet) {
        let books = goal.sortedBooks
        for index in offsets {
            modelContext.delete(books[index])
        }
        goal.updateProgress()
    }
}

struct BookRowView: View {
    let book: Book

    var body: some View {
        HStack(spacing: 12) {
            CoverImageView(url: book.coverURL, width: 50, height: 75)

            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.headline)
                    .lineLimit(2)

                if let author = book.author {
                    Text(author)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                HStack {
                    if book.isCompleted {
                        Label("Completed", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    } else if let pages = book.totalPages, pages > 0 {
                        Text("Page \(book.currentPage) of \(pages)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if book.totalChaptersCount > 0 {
                        Text("\(book.completedChaptersCount)/\(book.totalChaptersCount) chapters")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Goal.self, configurations: config)
    let goal = Goal(title: "Read 12 Books", goalType: .bookReading, targetValue: 12)
    container.mainContext.insert(goal)

    return NavigationStack {
        BookGoalDetailView(goal: goal)
    }
    .modelContainer(container)
}
