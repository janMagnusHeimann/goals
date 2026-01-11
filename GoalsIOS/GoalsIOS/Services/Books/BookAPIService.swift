import Foundation

enum BookAPIError: Error, LocalizedError {
    case invalidISBN
    case networkError(Error)
    case noResults
    case decodingError
    case invalidURL

    var errorDescription: String? {
        switch self {
        case .invalidISBN:
            return "Invalid ISBN format"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .noResults:
            return "No books found"
        case .decodingError:
            return "Failed to parse book data"
        case .invalidURL:
            return "Invalid URL"
        }
    }
}

struct BookSearchResult: Identifiable, Hashable {
    let id: String
    let title: String
    let authors: [String]
    let isbn10: String?
    let isbn13: String?
    let coverURL: String?
    let pageCount: Int?
    let description: String?
    let publishedDate: String?
    let publisher: String?

    var authorsString: String {
        authors.joined(separator: ", ")
    }

    var bestISBN: String? {
        isbn13 ?? isbn10
    }
}

actor BookAPIService {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func searchByISBN(_ isbn: String) async throws -> BookSearchResult? {
        let cleanISBN = isbn.replacingOccurrences(of: "-", with: "").trimmingCharacters(in: .whitespaces)

        guard !cleanISBN.isEmpty else {
            throw BookAPIError.invalidISBN
        }

        guard let url = URL(string: "\(Constants.API.googleBooksBaseURL)?q=isbn:\(cleanISBN)") else {
            throw BookAPIError.invalidURL
        }

        let (data, _) = try await session.data(from: url)
        let response = try JSONDecoder().decode(GoogleBooksResponse.self, from: data)

        guard let item = response.items?.first else {
            throw BookAPIError.noResults
        }

        return mapToSearchResult(item)
    }

    func search(query: String) async throws -> [BookSearchResult] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespaces)

        guard !trimmedQuery.isEmpty else {
            return []
        }

        guard let encoded = trimmedQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(Constants.API.googleBooksBaseURL)?q=\(encoded)&maxResults=20") else {
            throw BookAPIError.invalidURL
        }

        let (data, _) = try await session.data(from: url)
        let response = try JSONDecoder().decode(GoogleBooksResponse.self, from: data)

        return (response.items ?? []).compactMap { mapToSearchResult($0) }
    }

    func getOpenLibraryCoverURL(isbn: String, size: CoverSize = .medium) -> String {
        "\(Constants.API.openLibraryCoversURL)/\(isbn)-\(size.rawValue).jpg"
    }

    private func mapToSearchResult(_ item: GoogleBookItem) -> BookSearchResult {
        let info = item.volumeInfo
        let isbn10 = info.industryIdentifiers?.first { $0.type == "ISBN_10" }?.identifier
        let isbn13 = info.industryIdentifiers?.first { $0.type == "ISBN_13" }?.identifier

        var coverURL = info.imageLinks?.thumbnail?.replacingOccurrences(of: "http://", with: "https://")

        if coverURL == nil, let isbn = isbn13 ?? isbn10 {
            coverURL = getOpenLibraryCoverURL(isbn: isbn)
        }

        return BookSearchResult(
            id: item.id,
            title: info.title,
            authors: info.authors ?? [],
            isbn10: isbn10,
            isbn13: isbn13,
            coverURL: coverURL,
            pageCount: info.pageCount,
            description: info.description,
            publishedDate: info.publishedDate,
            publisher: info.publisher
        )
    }

    enum CoverSize: String {
        case small = "S"
        case medium = "M"
        case large = "L"
    }
}

// MARK: - Google Books API Response Models

struct GoogleBooksResponse: Codable {
    let totalItems: Int
    let items: [GoogleBookItem]?
}

struct GoogleBookItem: Codable {
    let id: String
    let volumeInfo: VolumeInfo
}

struct VolumeInfo: Codable {
    let title: String
    let authors: [String]?
    let description: String?
    let pageCount: Int?
    let imageLinks: ImageLinks?
    let industryIdentifiers: [IndustryIdentifier]?
    let publishedDate: String?
    let publisher: String?
}

struct ImageLinks: Codable {
    let smallThumbnail: String?
    let thumbnail: String?
}

struct IndustryIdentifier: Codable {
    let type: String
    let identifier: String
}
