import SwiftUI
import SwiftData

struct BookDetailView: View {
    @Bindable var book: Book

    @Environment(\.modelContext) private var modelContext
    @State private var showingAddChapter = false

    var body: some View {
        List {
            Section {
                HStack(spacing: 16) {
                    CoverImageView(url: book.coverURL, width: 100, height: 150)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(book.title)
                            .font(.title3)
                            .fontWeight(.semibold)

                        if let author = book.author {
                            Text(author)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        if let pages = book.totalPages {
                            Text("\(pages) pages")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        if book.isCompleted {
                            Label("Completed", systemImage: "checkmark.circle.fill")
                                .font(.subheadline)
                                .foregroundStyle(.green)
                        }
                    }
                }
                .padding(.vertical, 8)
            }

            if let pages = book.totalPages, pages > 0 {
                Section("Progress") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Page \(book.currentPage) of \(pages)")
                            Spacer()
                            Text("\(book.readingProgressPercentage)%")
                                .foregroundStyle(.secondary)
                        }

                        ProgressView(value: book.readingProgress)
                            .tint(.blue)

                        Stepper("Current page: \(book.currentPage)", value: $book.currentPage, in: 0...pages)
                    }
                }
            }

            Section {
                if book.sortedChapters.isEmpty {
                    Text("No chapters added")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(book.sortedChapters) { chapter in
                        NavigationLink {
                            ChapterNotesView(chapter: chapter)
                        } label: {
                            ChapterRowView(chapter: chapter)
                        }
                    }
                    .onDelete(perform: deleteChapters)
                }
            } header: {
                HStack {
                    Text("Chapters")
                    Spacer()
                    Button {
                        showingAddChapter = true
                    } label: {
                        Image(systemName: "plus.circle")
                    }
                }
            }

            if !book.isCompleted {
                Section {
                    Button {
                        book.markAsCompleted()
                        book.goal?.updateProgress()
                    } label: {
                        Label("Mark as Completed", systemImage: "checkmark.circle")
                    }
                }
            }
        }
        .navigationTitle("Book Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddChapter) {
            AddChapterSheet(book: book)
        }
    }

    private func deleteChapters(at offsets: IndexSet) {
        let chapters = book.sortedChapters
        for index in offsets {
            modelContext.delete(chapters[index])
        }
    }
}

struct ChapterRowView: View {
    @Bindable var chapter: Chapter

    var body: some View {
        HStack {
            Button {
                chapter.toggleCompleted()
            } label: {
                Image(systemName: chapter.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(chapter.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(chapter.title)
                    .strikethrough(chapter.isCompleted)

                if chapter.hasNotes {
                    Text("\(chapter.notesCount) note\(chapter.notesCount == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Book.self, configurations: config)
    let book = Book(title: "The Great Gatsby", author: "F. Scott Fitzgerald")
    book.totalPages = 180
    book.currentPage = 45
    container.mainContext.insert(book)

    return NavigationStack {
        BookDetailView(book: book)
    }
    .modelContainer(container)
}
