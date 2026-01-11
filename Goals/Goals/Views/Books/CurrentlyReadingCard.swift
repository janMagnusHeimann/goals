import SwiftUI

struct CurrentlyReadingCard: View {
    let book: Book
    var onLogReading: (() -> Void)?

    var body: some View {
        HStack(spacing: 20) {
            // Book Cover with Progress Ring
            ZStack {
                // Cover image
                if let coverURL = book.coverURL, let url = URL(string: coverURL) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        bookPlaceholder
                    }
                    .frame(width: 100, height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                } else {
                    bookPlaceholder
                        .frame(width: 100, height: 150)
                }

                // Progress ring overlay
                Circle()
                    .trim(from: 0, to: book.readingProgress)
                    .stroke(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 120, height: 120)
                    .offset(y: 15)
            }

            // Book Details
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Currently Reading")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    Text(book.title)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .lineLimit(2)

                    if let author = book.author {
                        Text(author)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                // Progress Section
                VStack(alignment: .leading, spacing: 8) {
                    // Progress Bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.blue.opacity(0.2))
                                .frame(height: 8)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [.blue, .cyan],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * book.readingProgress, height: 8)
                        }
                    }
                    .frame(height: 8)

                    // Progress Stats
                    HStack {
                        if let total = book.totalPages {
                            Text("Page \(book.currentPage) of \(total)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text("\(book.readingProgressPercentage)%")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.blue)
                    }
                }

                // Estimates Row
                HStack(spacing: 16) {
                    if book.averagePagesPerDay > 0 {
                        Label(book.formattedPagesPerDay, systemImage: "chart.line.uptrend.xyaxis")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let estimate = book.formattedEstimatedCompletion {
                        Label("Est. \(estimate)", systemImage: "calendar")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Actions
                if let onLog = onLogReading {
                    Button(action: onLog) {
                        Label("Log Reading", systemImage: "plus.circle.fill")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }

            Spacer()
        }
        .padding(20)
        .background(Color.goalCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var bookPlaceholder: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.blue.opacity(0.1))
            .overlay {
                Image(systemName: "book.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.blue.opacity(0.5))
            }
    }
}

// MARK: - Compact Currently Reading Card

struct CompactCurrentlyReadingCard: View {
    let book: Book

    var body: some View {
        HStack(spacing: 12) {
            // Mini Cover
            if let coverURL = book.coverURL, let url = URL(string: coverURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.blue.opacity(0.1))
                }
                .frame(width: 40, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 4))
            } else {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 40, height: 60)
                    .overlay {
                        Image(systemName: "book.fill")
                            .font(.caption)
                            .foregroundStyle(.blue.opacity(0.5))
                    }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                if let author = book.author {
                    Text(author)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                HStack(spacing: 8) {
                    MiniProgressRing(progress: book.readingProgress, color: .blue, size: 24)

                    if let total = book.totalPages {
                        Text("\(book.currentPage)/\(total)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()
        }
        .padding(12)
        .background(Color.goalCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Preview

#Preview {
    let book = Book(title: "The Pragmatic Programmer", author: "David Thomas, Andrew Hunt")
    book.totalPages = 352
    book.currentPage = 156
    book.coverURL = "https://covers.openlibrary.org/b/isbn/9780135957059-M.jpg"
    book.startedReadingDate = Calendar.current.date(byAdding: .day, value: -10, to: Date())

    return VStack(spacing: 20) {
        CurrentlyReadingCard(book: book) {
            print("Log reading")
        }

        CompactCurrentlyReadingCard(book: book)
    }
    .padding()
    .frame(width: 500)
}
