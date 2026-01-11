import SwiftUI
import SwiftData

struct BookGoalDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var goal: Goal
    @State private var selectedBook: Book?
    @State private var showingAddBookSheet = false
    @State private var showingLogReadingSheet = false
    @State private var searchText = ""

    private var filteredBooks: [Book] {
        let books = goal.sortedBooks
        if searchText.isEmpty {
            return books
        }
        return books.filter { book in
            book.title.localizedCaseInsensitiveContains(searchText) ||
            (book.author?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    private var currentlyReadingBook: Book? {
        goal.currentlyReadingBook
    }

    private var allReadingSessions: [ReadingSession] {
        goal.sortedBooks.flatMap { $0.sortedReadingSessions }
    }

    var body: some View {
        HSplitView {
            bookListSection
                .frame(minWidth: 300, maxWidth: 450)

            bookDetailSection
        }
        .sheet(isPresented: $showingAddBookSheet) {
            AddBookSheet(goal: goal) { book in
                modelContext.insert(book)
                book.goal = goal
                goal.updateProgress()
                selectedBook = book
            }
        }
        .sheet(isPresented: $showingLogReadingSheet) {
            if let book = currentlyReadingBook {
                LogReadingSheet(book: book, onSave: { session in
                    modelContext.insert(session)
                    session.book = book
                    // Update book's current page based on session
                    book.currentPage = min(book.currentPage + session.pagesRead, book.totalPages ?? book.currentPage + session.pagesRead)
                    book.lastReadDate = Date()
                })
            }
        }
        .onAppear {
            if selectedBook == nil {
                selectedBook = goal.sortedBooks.first
            }
        }
    }

    private var bookListSection: some View {
        VStack(spacing: 0) {
            GoalProgressHeader(goal: goal)
                .padding()

            // Currently Reading Spotlight
            if let currentBook = currentlyReadingBook {
                Divider()
                CurrentlyReadingCard(
                    book: currentBook,
                    onLogReading: {
                        showingLogReadingSheet = true
                    },
                    onContinueReading: {
                        selectedBook = currentBook
                    }
                )
                .padding()
            }

            // Reading Stats
            if !allReadingSessions.isEmpty {
                Divider()
                ReadingStatsView(
                    sessions: allReadingSessions,
                    books: goal.sortedBooks,
                    compact: true
                )
                .padding()
            }

            Divider()

            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search books...", text: $searchText)
                    .textFieldStyle(.plain)

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(Color.goalCardBackground)

            Divider()

            if filteredBooks.isEmpty {
                ContentUnavailableView {
                    Label(
                        searchText.isEmpty ? "No Books Yet" : "No Results",
                        systemImage: searchText.isEmpty ? "book" : "magnifyingglass"
                    )
                } description: {
                    Text(searchText.isEmpty
                         ? "Add your first book to start tracking"
                         : "No books match '\(searchText)'")
                } actions: {
                    if searchText.isEmpty {
                        Button("Add Book") {
                            showingAddBookSheet = true
                        }
                    }
                }
                .frame(maxHeight: .infinity)
            } else {
                List(filteredBooks, selection: $selectedBook) { book in
                    BookRowView(book: book)
                        .tag(book)
                        .contextMenu {
                            Button(book.isCompleted ? "Mark as Unread" : "Mark as Completed") {
                                if book.isCompleted {
                                    book.isCompleted = false
                                    book.completionDate = nil
                                } else {
                                    book.markAsCompleted()
                                }
                                goal.updateProgress()
                            }

                            Divider()

                            Button("Delete", role: .destructive) {
                                deleteBook(book)
                            }
                        }
                }
                .listStyle(.plain)
            }

            Divider()

            HStack {
                Text("\(goal.completedBooks.count) of \(goal.sortedBooks.count) books completed")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    showingAddBookSheet = true
                } label: {
                    Label("Add Book", systemImage: "plus")
                }
                .buttonStyle(.borderless)
            }
            .padding(12)
        }
        .background(Color.goalSecondaryBackground)
    }

    @ViewBuilder
    private var bookDetailSection: some View {
        if let book = selectedBook {
            BookDetailView(book: book, onUpdate: {
                goal.updateProgress()
            })
        } else {
            EmptyStateView(
                title: "No Book Selected",
                message: "Select a book from the list to view details and notes",
                systemImage: "book.closed"
            )
        }
    }

    private func deleteBook(_ book: Book) {
        if selectedBook?.id == book.id {
            selectedBook = nil
        }
        modelContext.delete(book)
        goal.updateProgress()
    }
}

struct BookRowView: View {
    @Bindable var book: Book

    var body: some View {
        HStack(spacing: 12) {
            SmallCoverImageView(url: book.coverURL)

            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.system(.body, weight: .medium))
                    .lineLimit(2)

                if let author = book.author {
                    Text(author)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                HStack(spacing: 8) {
                    if book.isCompleted {
                        Label("Completed", systemImage: "checkmark.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(.green)
                    } else if let pages = book.totalPages, pages > 0 {
                        Text("Page \(book.currentPage) of \(pages)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    if book.totalChaptersCount > 0 {
                        Text("\(book.completedChaptersCount)/\(book.totalChaptersCount) chapters")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Spacer()

            if book.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Goal.self, configurations: config)

    let goal = Goal(title: "Read 100 Books", goalType: .bookReading, targetValue: 100)
    container.mainContext.insert(goal)

    return BookGoalDetailView(goal: goal)
        .modelContainer(container)
        .frame(width: 900, height: 600)
}
