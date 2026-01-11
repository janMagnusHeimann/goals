import SwiftUI

struct AddChapterSheet: View {
    @Environment(\.dismiss) private var dismiss
    let book: Book
    let onAdd: (Chapter) -> Void

    @State private var title = ""
    @State private var pageStart = ""
    @State private var pageEnd = ""

    private var nextOrderIndex: Int {
        (book.chapters?.count ?? 0) + 1
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Add Chapter")
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

            Divider()

            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Chapter Title")
                        .font(.headline)

                    TextField("Chapter \(nextOrderIndex)", text: $title)
                        .textFieldStyle(.roundedBorder)
                }

                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Start Page")
                            .font(.headline)

                        TextField("Optional", text: $pageStart)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("End Page")
                            .font(.headline)

                        TextField("Optional", text: $pageEnd)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                    }
                }

                Spacer()
            }
            .padding(20)

            Divider()

            HStack {
                Spacer()

                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape)

                Button("Add Chapter") {
                    addChapter()
                }
                .buttonStyle(.borderedProminent)
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                .keyboardShortcut(.return)
            }
            .padding(20)
        }
        .frame(width: 400, height: 320)
    }

    private func addChapter() {
        let chapterTitle = title.trimmingCharacters(in: .whitespaces).isEmpty
            ? "Chapter \(nextOrderIndex)"
            : title.trimmingCharacters(in: .whitespaces)

        let chapter = Chapter(title: chapterTitle, orderIndex: nextOrderIndex)

        if let start = Int(pageStart) {
            chapter.pageStart = start
        }
        if let end = Int(pageEnd) {
            chapter.pageEnd = end
        }

        onAdd(chapter)
        dismiss()
    }
}

struct EditChapterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var chapter: Chapter

    @State private var title: String
    @State private var pageStart: String
    @State private var pageEnd: String

    init(chapter: Chapter) {
        self.chapter = chapter
        _title = State(initialValue: chapter.title)
        _pageStart = State(initialValue: chapter.pageStart.map(String.init) ?? "")
        _pageEnd = State(initialValue: chapter.pageEnd.map(String.init) ?? "")
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Edit Chapter")
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

            Divider()

            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Chapter Title")
                        .font(.headline)

                    TextField("Chapter title", text: $title)
                        .textFieldStyle(.roundedBorder)
                }

                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Start Page")
                            .font(.headline)

                        TextField("Optional", text: $pageStart)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("End Page")
                            .font(.headline)

                        TextField("Optional", text: $pageEnd)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                    }
                }

                Spacer()
            }
            .padding(20)

            Divider()

            HStack {
                Spacer()

                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape)

                Button("Save") {
                    saveChanges()
                }
                .buttonStyle(.borderedProminent)
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                .keyboardShortcut(.return)
            }
            .padding(20)
        }
        .frame(width: 400, height: 320)
    }

    private func saveChanges() {
        chapter.title = title.trimmingCharacters(in: .whitespaces)
        chapter.pageStart = Int(pageStart)
        chapter.pageEnd = Int(pageEnd)
        dismiss()
    }
}

struct EditNoteSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var note: ChapterNote

    @State private var content: String

    init(note: ChapterNote) {
        self.note = note
        _content = State(initialValue: note.content)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Edit Note")
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

            Divider()

            TextEditor(text: $content)
                .font(.body)
                .padding(8)
                .scrollContentBackground(.hidden)
                .background(Color.goalCardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.goalBorder, lineWidth: 1)
                )
                .padding(20)

            Divider()

            HStack {
                Text("Last edited \(note.updatedAt.relativeFormatted)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                Spacer()

                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape)

                Button("Save") {
                    note.update(content: content)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(content.trimmingCharacters(in: .whitespaces).isEmpty)
                .keyboardShortcut(.return)
            }
            .padding(20)
        }
        .frame(width: 500, height: 400)
    }
}

#Preview("Add Chapter") {
    AddChapterSheet(book: Book(title: "Test")) { _ in }
}

#Preview("Edit Note") {
    EditNoteSheet(note: ChapterNote(content: "This is a sample note with some content to edit."))
}
