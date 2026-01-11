import SwiftUI

struct CoverImageView: View {
    let url: String?
    var width: CGFloat = 80
    var height: CGFloat = 120

    var body: some View {
        Group {
            if let urlString = url, let imageURL = URL(string: urlString) {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .empty:
                        placeholderView
                            .overlay {
                                ProgressView()
                            }
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        placeholderView
                    @unknown default:
                        placeholderView
                    }
                }
            } else {
                placeholderView
            }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var placeholderView: some View {
        Rectangle()
            .fill(Color.goalCardBackground)
            .overlay {
                Image(systemName: "book.closed.fill")
                    .font(.title)
                    .foregroundStyle(.secondary)
            }
    }
}

#Preview {
    HStack {
        CoverImageView(url: nil)
        CoverImageView(url: "https://covers.openlibrary.org/b/isbn/9780141439518-M.jpg")
    }
    .padding()
}
