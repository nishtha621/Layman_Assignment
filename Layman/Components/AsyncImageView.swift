import SwiftUI

// MARK: - AsyncImageView

/// A reusable remote image loader with placeholder, error state, smooth fade-in,
/// and URL sanity checking (filters out known source logos / non-photo urls).
struct AsyncImageView: View {

    let urlString: String?
    var contentMode: ContentMode = .fill

    var body: some View {
        Group {
            if let urlString, isValidImageURL(urlString), let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        imagePlaceholder
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: contentMode)
                            .transition(.opacity.animation(.easeIn(duration: 0.25)))
                    case .failure:
                        imageError
                    @unknown default:
                        imagePlaceholder
                    }
                }
            } else {
                imageError
            }
        }
    }

    // MARK: - URL Sanity Check

    /// Returns false for obviously non-photo URLs (source logos, SVGs, tiny icons, etc.)
    private func isValidImageURL(_ urlString: String) -> Bool {
        guard !urlString.isEmpty, urlString.hasPrefix("http") else { return false }
        let lower = urlString.lowercased()
        // Skip SVGs and GIFs (usually logos/icons)
        if lower.hasSuffix(".svg") || lower.hasSuffix(".gif") { return false }
        // Must look like an image path
        let imageExtensions = [".jpg", ".jpeg", ".png", ".webp", ".avif"]
        let hasImageExtension = imageExtensions.contains { lower.contains($0) }
        // Also allow URLs without extensions (CDN URLs like newsdata.io uses)
        return hasImageExtension || (!lower.contains("icon") && !lower.contains("logo") && !lower.contains("avatar"))
    }

    // MARK: - Placeholder

    private var imagePlaceholder: some View {
        Rectangle()
            .fill(Color(hex: "#EDE0D6"))
            .overlay(
                ProgressView()
                    .tint(AppColors.accentOrange)
            )
    }

    // MARK: - Error / No Image

    private var imageError: some View {
        ZStack {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#F5E8DF"), Color(hex: "#EDD5C5")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            VStack(spacing: 6) {
                Image(systemName: "photo")
                    .font(.system(size: 22))
                    .foregroundColor(AppColors.textTertiary)
                Text("No Image")
                    .font(AppFonts.caption(size: 11))
                    .foregroundColor(AppColors.textTertiary)
            }
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        AsyncImageView(urlString: "https://picsum.photos/400/200")
            .frame(width: 360, height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 12))

        AsyncImageView(urlString: nil)
            .frame(width: 360, height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    .padding()
}
