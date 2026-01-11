import SwiftUI
import SwiftData

struct ChapterNotesView: View {
    @Bindable var chapter: Chapter

    @Environment(\.modelContext) private var modelContext
    @State private var showingAddNote = false

    var body: some View {
        List {
            Section {
                HStack {
                    Button {
                        chapter.toggleCompleted()
                    } label: {
                        Image(systemName: chapter.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(chapter.isCompleted ? .green : .secondary)
                    }
                    .buttonStyle(.plain)

                    Text(chapter.title)
                        .font(.headline)
                }

                if let pageRange = chapter.pageRange {
                    Text(pageRange)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                if chapter.sortedNotes.isEmpty {
                    Text("No notes yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(chapter.sortedNotes) { note in
                        NavigationLink {
                            NoteEditorView(note: note)
                        } label: {
                            NoteRowView(note: note)
                        }
                    }
                    .onDelete(perform: deleteNotes)
                }
            } header: {
                HStack {
                    Text("Notes")
                    Spacer()
                    Button {
                        showingAddNote = true
                    } label: {
                        Image(systemName: "plus.circle")
                    }
                }
            }
        }
        .navigationTitle("Chapter Notes")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddNote) {
            AddNoteSheet(chapter: chapter)
        }
    }

    private func deleteNotes(at offsets: IndexSet) {
        let notes = chapter.sortedNotes
        for index in offsets {
            modelContext.delete(notes[index])
        }
    }
}

struct NoteRowView: View {
    let note: ChapterNote

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(note.preview)
                .lineLimit(3)

            Text(note.createdAt.relativeFormatted)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct NoteEditorView: View {
    @Bindable var note: ChapterNote

    @State private var content: String

    init(note: ChapterNote) {
        self.note = note
        _content = State(initialValue: note.content)
    }

    var body: some View {
        TextEditor(text: $content)
            .padding()
            .navigationTitle("Edit Note")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: content) {
                note.update(content: content)
            }
    }
}

struct AddNoteSheet: View {
    let chapter: Chapter

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var content = ""

    var body: some View {
        NavigationStack {
            TextEditor(text: $content)
                .padding()
                .navigationTitle("New Note")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }

                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") {
                            addNote()
                        }
                        .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
        }
    }

    private func addNote() {
        let note = ChapterNote(content: content.trimmingCharacters(in: .whitespacesAndNewlines))
        note.chapter = chapter
        modelContext.insert(note)
        dismiss()
    }
}

struct AddChapterSheet: View {
    let book: Book

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var pageStart = ""
    @State private var pageEnd = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Chapter Title", text: $title)

                Section("Page Range (optional)") {
                    TextField("Start Page", text: $pageStart)
                        .keyboardType(.numberPad)
                    TextField("End Page", text: $pageEnd)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("Add Chapter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addChapter()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func addChapter() {
        let orderIndex = (book.chapters?.count ?? 0)
        let chapter = Chapter(
            title: title.trimmingCharacters(in: .whitespaces),
            orderIndex: orderIndex
        )

        if let start = Int(pageStart), start > 0 {
            chapter.pageStart = start
        }
        if let end = Int(pageEnd), end > 0 {
            chapter.pageEnd = end
        }

        chapter.book = book
        modelContext.insert(chapter)
        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Chapter.self, configurations: config)
    let chapter = Chapter(title: "Chapter 1: The Beginning", orderIndex: 0)
    container.mainContext.insert(chapter)

    return NavigationStack {
        ChapterNotesView(chapter: chapter)
    }
    .modelContainer(container)
}
