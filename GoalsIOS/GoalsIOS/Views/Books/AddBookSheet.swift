import SwiftUI
import SwiftData

struct AddBookSheet: View {
    let goal: Goal

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var searchQuery = ""
    @State private var searchResults: [BookSearchResult] = []
    @State private var isSearching = false
    @State private var errorMessage: String?

    @State private var manualTitle = ""
    @State private var manualAuthor = ""
    @State private var manualPages = ""

    @State private var showingManualEntry = false

    private let bookService = BookAPIService()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        TextField("Search by title or ISBN", text: $searchQuery)
                            .textFieldStyle(.plain)
                            .autocorrectionDisabled()

                        if isSearching {
                            ProgressView()
                        } else if !searchQuery.isEmpty {
                            Button {
                                Task { await search() }
                            } label: {
                                Image(systemName: "magnifyingglass")
                            }
                        }
                    }
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }

                if !searchResults.isEmpty {
                    Section("Search Results") {
                        ForEach(searchResults) { result in
                            Button {
                                addBook(from: result)
                            } label: {
                                SearchResultRow(result: result)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Section {
                    Button {
                        showingManualEntry = true
                    } label: {
                        Label("Add Manually", systemImage: "square.and.pencil")
                    }
                }
            }
            .navigationTitle("Add Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingManualEntry) {
                ManualBookEntrySheet(goal: goal)
            }
            .onSubmit {
                Task { await search() }
            }
        }
    }

    private func search() async {
        guard !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        isSearching = true
        errorMessage = nil

        do {
            searchResults = try await bookService.search(query: searchQuery)
            if searchResults.isEmpty {
                errorMessage = "No books found"
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isSearching = false
    }

    private func addBook(from result: BookSearchResult) {
        let book = Book(
            title: result.title,
            author: result.authorsString.isEmpty ? nil : result.authorsString,
            isbn: result.bestISBN
        )
        book.coverURL = result.coverURL
        book.totalPages = result.pageCount
        book.bookDescription = result.description
        book.googleBooksId = result.id
        book.goal = goal

        modelContext.insert(book)
        goal.updateProgress()
        dismiss()
    }
}

struct SearchResultRow: View {
    let result: BookSearchResult

    var body: some View {
        HStack(spacing: 12) {
            CoverImageView(url: result.coverURL, width: 50, height: 75)

            VStack(alignment: .leading, spacing: 4) {
                Text(result.title)
                    .font(.headline)
                    .lineLimit(2)

                if !result.authorsString.isEmpty {
                    Text(result.authorsString)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                if let pages = result.pageCount {
                    Text("\(pages) pages")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(systemName: "plus.circle.fill")
                .foregroundStyle(.blue)
        }
    }
}

struct ManualBookEntrySheet: View {
    let goal: Goal

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var author = ""
    @State private var pages = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $title)
                TextField("Author (optional)", text: $author)
                TextField("Total Pages (optional)", text: $pages)
                    .keyboardType(.numberPad)
            }
            .navigationTitle("Add Book Manually")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addBook()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func addBook() {
        let book = Book(
            title: title.trimmingCharacters(in: .whitespaces),
            author: author.trimmingCharacters(in: .whitespaces).isEmpty ? nil : author.trimmingCharacters(in: .whitespaces)
        )

        if let pageCount = Int(pages), pageCount > 0 {
            book.totalPages = pageCount
        }

        book.goal = goal
        modelContext.insert(book)
        goal.updateProgress()
        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Goal.self, configurations: config)
    let goal = Goal(title: "Read 12 Books", goalType: .bookReading, targetValue: 12)
    container.mainContext.insert(goal)

    return AddBookSheet(goal: goal)
        .modelContainer(container)
}
