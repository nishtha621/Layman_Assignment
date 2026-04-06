import SwiftUI

// MARK: - FeaturedCarouselView

struct FeaturedCarouselView: View {

    let articles: [Article]
    @Binding var currentIndex: Int
    let onTap: (Article) -> Void

    var body: some View {
        TabView(selection: $currentIndex) {
            ForEach(Array(articles.enumerated()), id: \.element.id) { index, article in
                FeaturedCardView(article: article)
                    .padding(.horizontal, 20)
                    .onTapGesture { onTap(article) }
                    .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: 0))  // TabView clips to bounds
    }
}

// MARK: - FeaturedCardView

struct FeaturedCardView: View {

    let article: Article

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background image — fills the card
            AsyncImageView(urlString: article.imageURL)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 18))

            // Bottom gradient for text readability
            LinearGradient(
                colors: [.clear, .black.opacity(0.72)],
                startPoint: .center,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 18))

            // Text overlay
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(article.sourceName.uppercased())
                        .font(AppFonts.caption(size: 10))
                        .fontWeight(.bold)
                        .foregroundColor(.white.opacity(0.85))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(AppColors.accentOrange.opacity(0.85))
                        .clipShape(Capsule())

                    Text(article.formattedDate)
                        .font(AppFonts.caption(size: 11))
                        .foregroundColor(.white.opacity(0.7))
                }

                Text(article.headline)
                    .font(AppFonts.headline(size: 16))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.14), radius: 12, x: 0, y: 4)
    }
}

// MARK: - CarouselSkeletonView

struct CarouselSkeletonView: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 18)
            .fill(Color(hex: "#EDE0D6"))
            .frame(height: 220)
            .padding(.horizontal, 20)
            .shimmering()
    }
}

// MARK: - Collection safe subscript

extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
