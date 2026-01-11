import SwiftUI
import SwiftData

struct BookDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var book: Book
    let onUpdate: () -> Void

    @State private var expandedChapters: Set<UUID> = []
    @State private var showingAddChapter = false
    @State private var editingChapter: Chapter?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                bookHeader

                Divider()

                readingProgressSection

                Divider()

                chaptersSection
            }
            .padding(24)
        }
        .background(Color.goalSecondaryBackground)
        .sheet(isPresented: $showingAddChapter) {
            AddChapterSheet(book: book) { chapter in
                modelContext.insert(chapter)
                chapter.book = book
            }
        }
        .sheet(item: $editingChapter) { chapter in
            EditChapterSheet(chapter: chapter)
        }
    }

    private var bookHeader: some View {
        HStack(alignment: .top, spacing: 20) {
            LargeCoverImageView(url: book.coverURL)

            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(book.title)
                        .font(.title)
                        .fontWeight(.bold)

                    if let author = book.author {
                        Text(author)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(spacing: 16) {
                    if let pages = book.totalPages {
                        Label("\(pages) pages", systemImage: "doc.text")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let isbn = book.isbn {
                        Label(isbn, systemImage: "barcode")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if book.isCompleted {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Completed")
                            .fontWeight(.medium)
                        if let date = book.completionDate {
                            Text("on \(date.shortFormatted)")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .font(.subheadline)
                } else {
                    Button {
                        book.markAsCompleted()
                        onUpdate()
                    } label: {
                        Label("Mark as Completed", systemImage: "checkmark.circle")
                    }
                    .buttonStyle(.borderedProminent)
                }

                if let description = book.bookDescription {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(4)
                }
            }

            Spacer()
        }
    }

    private var readingProgressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reading Progress")
                .font(.headline)

            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current Page")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack {
                        TextField("0", value: $book.currentPage, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)

                        if let total = book.totalPages {
                            Text("of \(total)")
                                .foregroundStyle(.secondary)
                        }

                        Stepper("", value: $book.currentPage, in: 0...(book.totalPages ?? 10000))
                            .labelsHidden()
                    }
                }

                if book.totalPages != nil {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(book.readingProgressPercentage)% Complete")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        ProgressView(value: book.readingProgress)
                            .frame(width: 200)
                    }
                }
            }
        }
        .padding()
        .background(Color.goalCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var chaptersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Chapters & Notes")
                    .font(.headline)

                Spacer()

                Button {
                    showingAddChapter = true
                } label: {
                    Label("Add Chapter", systemImage: "plus")
                }
                .buttonStyle(.borderless)
            }

            if book.sortedChapters.isEmpty {
                ContentUnavailableView {
                    Label("No Chapters", systemImage: "list.bullet")
                } description: {
                    Text("Add chapters to organize your notes")
                } actions: {
                    Button("Add Chapter") {
                        showingAddChapter = true
                    }
                }
                .frame(height: 200)
            } else {
                VStack(spacing: 8) {
                    ForEach(book.sortedChapters) { chapter in
                        ChapterDisclosureView(
                            chapter: chapter,
                            isExpanded: expandedChapters.contains(chapter.id),
                            onToggle: {
                                toggleChapter(chapter)
                            },
                            onEdit: {
                                editingChapter = chapter
                            },
                            onDelete: {
                                deleteChapter(chapter)
                            }
                        )
                    }
                }
            }
        }
    }

    private func toggleChapter(_ chapter: Chapter) {
        if expandedChapters.contains(chapter.id) {
            expandedChapters.remove(chapter.id)
        } else {
            expandedChapters.insert(chapter.id)
        }
    }

    private func deleteChapter(_ chapter: Chapter) {
        modelContext.delete(chapter)
    }
}

struct ChapterDisclosureView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var chapter: Chapter
    let isExpanded: Bool
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var newNoteContent = ""
    @State private var editingNote: ChapterNote?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            chapterHeader

            if isExpanded {
                Divider()
                    .padding(.horizontal)

                notesSection
                    .padding()
            }
        }
        .background(Color.goalCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.goalBorder, lineWidth: 1)
        )
    }

    private var chapterHeader: some View {
        HStack {
            Button(action: onToggle) {
                HStack(spacing: 12) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 12)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(chapter.title)
                            .font(.system(.body, weight: .medium))

                        HStack(spacing: 8) {
                            if let range = chapter.pageRange {
                                Text(range)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }

                            if chapter.notesCount > 0 {
                                Label("\(chapter.notesCount) notes", systemImage: "note.text")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                chapter.toggleCompleted()
            } label: {
                Image(systemName: chapter.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(chapter.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)

            Menu {
                Button("Edit Chapter", action: onEdit)
                Divider()
                Button("Delete", role: .destructive, action: onDelete)
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding()
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(chapter.sortedNotes) { note in
                NoteView(note: note) {
                    editingNote = note
                } onDelete: {
                    modelContext.delete(note)
                }
            }

            HStack {
                TextField("Add a note...", text: $newNoteContent, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...4)

                Button {
                    addNote()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
                .buttonStyle(.plain)
                .disabled(newNoteContent.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .sheet(item: $editingNote) { note in
            EditNoteSheet(note: note)
        }
    }

    private func addNote() {
        let content = newNoteContent.trimmingCharacters(in: .whitespaces)
        guard !content.isEmpty else { return }

        let note = ChapterNote(content: content)
        modelContext.insert(note)
        note.chapter = chapter

        newNoteContent = ""
    }
}

struct NoteView: View {
    @Bindable var note: ChapterNote
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(note.content)
                .font(.callout)

            HStack {
                Text(note.updatedAt.relativeFormatted)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                Spacer()

                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.red.opacity(0.7))
            }
        }
        .padding(12)
        .background(Color.goalSecondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Book.self, configurations: config)

    let book = Book(title: "The Pragmatic Programmer", author: "David Thomas, Andrew Hunt")
    book.totalPages = 352
    book.currentPage = 120
    container.mainContext.insert(book)

    return BookDetailView(book: book, onUpdate: {})
        .modelContainer(container)
        .frame(width: 600, height: 800)
}
