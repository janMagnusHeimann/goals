import SwiftUI

struct LogReadingSheet: View {
    @Environment(\.dismiss) private var dismiss

    let book: Book
    let onSave: (ReadingSession) -> Void

    @State private var pagesRead: String = ""
    @State private var durationMinutes: String = ""
    @State private var date: Date = Date()
    @State private var notes: String = ""
    @State private var startPage: String = ""

    private var pagesValue: Int {
        Int(pagesRead) ?? 0
    }

    private var durationValue: Int {
        Int(durationMinutes) ?? 0
    }

    private var isValid: Bool {
        pagesValue > 0 || durationValue > 0
    }

    private var projectedEndPage: Int {
        book.currentPage + pagesValue
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text("Log Reading Session")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text(book.title)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
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
            .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Current progress
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Currently on")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("Page \(book.currentPage)")
                                .font(.title3)
                                .fontWeight(.bold)
                        }

                        Spacer()

                        if let total = book.totalPages {
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Total pages")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("\(total)")
                                    .font(.title3)
                                    .fontWeight(.bold)
                            }
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    // Pages Read
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Pages Read")
                            .font(.headline)

                        HStack {
                            TextField("0", text: $pagesRead)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)

                            Text("pages")
                                .foregroundStyle(.secondary)

                            Spacer()

                            if pagesValue > 0 {
                                Text("→ Page \(projectedEndPage)")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            }
                        }

                        // Quick page buttons
                        HStack {
                            ForEach([10, 25, 50, 100], id: \.self) { pages in
                                Button("+\(pages)") {
                                    pagesRead = "\(pages)"
                                }
                                .buttonStyle(.bordered)
                                .tint(pagesRead == "\(pages)" ? .blue : .secondary)
                            }
                        }
                    }

                    // Duration
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Duration")
                            .font(.headline)

                        HStack {
                            TextField("0", text: $durationMinutes)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)

                            Text("minutes")
                                .foregroundStyle(.secondary)
                        }

                        // Quick duration buttons
                        HStack {
                            ForEach([15, 30, 45, 60], id: \.self) { mins in
                                Button("\(mins) min") {
                                    durationMinutes = "\(mins)"
                                }
                                .buttonStyle(.bordered)
                                .tint(durationMinutes == "\(mins)" ? .blue : .secondary)
                            }
                        }
                    }

                    // Date
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Date")
                            .font(.headline)
                        DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                            .labelsHidden()
                    }

                    // Notes
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes (optional)")
                            .font(.headline)
                        TextField("Any thoughts about this reading session...", text: $notes, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(2...4)
                    }

                    // Reading pace info
                    if pagesValue > 0 && durationValue > 0 {
                        HStack {
                            Image(systemName: "speedometer")
                                .foregroundStyle(.blue)
                            Text("Reading pace: \(String(format: "%.1f", Double(pagesValue) / (Double(durationValue) / 60))) pages/hour")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding()
            }

            Divider()

            // Footer
            HStack {
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape)

                Button("Log Session") {
                    saveSession()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isValid)
                .keyboardShortcut(.return)
            }
            .padding()
        }
        .frame(width: 400, height: 550)
        .onAppear {
            startPage = "\(book.currentPage)"
        }
    }

    private func saveSession() {
        let session = ReadingSession(
            pagesRead: pagesValue,
            durationMinutes: durationValue,
            startPage: book.currentPage,
            endPage: projectedEndPage,
            date: date,
            notes: notes.isEmpty ? nil : notes
        )

        onSave(session)
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    let book = Book(title: "The Great Gatsby", author: "F. Scott Fitzgerald")
    book.totalPages = 180
    book.currentPage = 45

    return LogReadingSheet(book: book) { session in
        print("Logged session: \(session.pagesRead) pages")
    }
}
