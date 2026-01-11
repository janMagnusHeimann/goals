import SwiftUI

struct AddBookSheet: View {
    @Environment(\.dismiss) private var dismiss
    let goal: Goal
    let onAdd: (Book) -> Void

    @State private var searchQuery = ""
    @State private var searchResults: [BookSearchResult] = []
    @State private var isSearching = false
    @State private var searchError: String?
    @State private var selectedTab = 0

    @State private var manualTitle = ""
    @State private var manualAuthor = ""
    @State private var manualISBN = ""
    @State private var manualPageCount = ""

    private let bookService = BookAPIService()

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()

            TabView(selection: $selectedTab) {
                searchTab
                    .tabItem { Label("Search", systemImage: "magnifyingglass") }
                    .tag(0)

                manualTab
                    .tabItem { Label("Manual", systemImage: "square.and.pencil") }
                    .tag(1)
            }
            .padding()
        }
        .frame(width: 550, height: 500)
    }

    private var header: some View {
        HStack {
            Text("Add Book")
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
        .padding(20)
    }

    private var searchTab: some View {
        VStack(spacing: 16) {
            HStack {
                TextField("Search by title, author, or ISBN...", text: $searchQuery)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        performSearch()
                    }

                Button("Search") {
                    performSearch()
                }
                .disabled(searchQuery.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            if isSearching {
                Spacer()
                ProgressView("Searching...")
                Spacer()
            } else if let error = searchError {
                Spacer()
                ContentUnavailableView {
                    Label("Search Failed", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(error)
                }
                Spacer()
            } else if searchResults.isEmpty && !searchQuery.isEmpty {
                Spacer()
                ContentUnavailableView {
                    Label("No Results", systemImage: "magnifyingglass")
                } description: {
                    Text("No books found for '\(searchQuery)'")
                }
                Spacer()
            } else if searchResults.isEmpty {
                Spacer()
                ContentUnavailableView {
                    Label("Search Books", systemImage: "book")
                } description: {
                    Text("Enter a title, author, or ISBN to search")
                }
                Spacer()
            } else {
                List(searchResults) { result in
                    SearchResultRow(result: result) {
                        addBookFromResult(result)
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    private var manualTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Title *")
                    .font(.headline)
                TextField("Book title", text: $manualTitle)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Author")
                    .font(.headline)
                TextField("Author name", text: $manualAuthor)
                    .textFieldStyle(.roundedBorder)
            }

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("ISBN")
                        .font(.headline)
                    TextField("ISBN-10 or ISBN-13", text: $manualISBN)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Pages")
                        .font(.headline)
                    TextField("Page count", text: $manualPageCount)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                }
            }

            Spacer()

            HStack {
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                Button("Add Book") {
                    addManualBook()
                }
                .buttonStyle(.borderedProminent)
                .disabled(manualTitle.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    private func performSearch() {
        let query = searchQuery.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return }

        isSearching = true
        searchError = nil

        Task {
            do {
                let results = try await bookService.search(query: query)
                await MainActor.run {
                    searchResults = results
                    isSearching = false
                }
            } catch {
                await MainActor.run {
                    searchError = error.localizedDescription
                    isSearching = false
                }
            }
        }
    }

    private func addBookFromResult(_ result: BookSearchResult) {
        let book = Book(
            title: result.title,
            author: result.authorsString.isEmpty ? nil : result.authorsString,
            isbn: result.bestISBN
        )
        book.coverURL = result.coverURL
        book.totalPages = result.pageCount
        book.bookDescription = result.description
        book.googleBooksId = result.id

        onAdd(book)
        dismiss()
    }

    private func addManualBook() {
        let book = Book(
            title: manualTitle.trimmingCharacters(in: .whitespaces),
            author: manualAuthor.isEmpty ? nil : manualAuthor,
            isbn: manualISBN.isEmpty ? nil : manualISBN
        )

        if let pages = Int(manualPageCount) {
            book.totalPages = pages
        }

        if let isbn = book.isbn {
            book.coverURL = "https://covers.openlibrary.org/b/isbn/\(isbn)-M.jpg"
        }

        onAdd(book)
        dismiss()
    }
}

struct SearchResultRow: View {
    let result: BookSearchResult
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                CoverImageView(url: result.coverURL, width: 50, height: 75)

                VStack(alignment: .leading, spacing: 4) {
                    Text(result.title)
                        .font(.system(.body, weight: .medium))
                        .lineLimit(2)
                        .foregroundStyle(.primary)

                    if !result.authorsString.isEmpty {
                        Text(result.authorsString)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    HStack(spacing: 8) {
                        if let pages = result.pageCount {
                            Text("\(pages) pages")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }

                        if let date = result.publishedDate {
                            Text(date)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }

                Spacer()

                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AddBookSheet(goal: Goal(title: "Test", goalType: .bookReading, targetValue: 10)) { _ in }
}
