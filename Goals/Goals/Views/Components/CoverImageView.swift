import SwiftUI

struct CoverImageView: View {
    let url: String?
    var width: CGFloat = 80
    var height: CGFloat = 120

    var body: some View {
        if let urlString = url, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    placeholderView
                        .overlay(ProgressView().scaleEffect(0.6))
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: width, height: height)
                        .clipped()
                case .failure:
                    placeholderView
                @unknown default:
                    placeholderView
                }
            }
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
        } else {
            placeholderView
        }
    }

    private var placeholderView: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(Color.secondary.opacity(0.15))
            .frame(width: width, height: height)
            .overlay(
                VStack(spacing: 4) {
                    Image(systemName: "book.closed")
                        .font(.system(size: width * 0.25))
                        .foregroundStyle(.secondary)

                    Text("No Cover")
                        .font(.system(size: 8))
                        .foregroundStyle(.tertiary)
                }
            )
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct LargeCoverImageView: View {
    let url: String?

    var body: some View {
        CoverImageView(url: url, width: 140, height: 210)
    }
}

struct SmallCoverImageView: View {
    let url: String?

    var body: some View {
        CoverImageView(url: url, width: 50, height: 75)
    }
}

#Preview {
    HStack(spacing: 20) {
        SmallCoverImageView(url: nil)

        CoverImageView(url: nil)

        LargeCoverImageView(url: nil)
    }
    .padding()
}
