import SwiftUI

// MARK: - ArticleRowView

struct ArticleRowView: View {

    let article: Article
    let isSaved: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // Thumbnail
            AsyncImageView(urlString: article.imageURL)
                .frame(width: 90, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            // Text content
            VStack(alignment: .leading, spacing: 6) {
                // Source + time
                HStack(spacing: 6) {
                    Text(article.sourceName.uppercased())
                        .font(AppFonts.caption(size: 10))
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.accentOrange)

                    Text("·")
                        .foregroundColor(AppColors.textTertiary)

                    Text(article.formattedDate)
                        .font(AppFonts.caption(size: 11))
                        .foregroundColor(AppColors.textTertiary)

                    Spacer()

                    if isSaved {
                        Image(systemName: "bookmark.fill")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.accentOrange)
                    }
                }

                // Headline — max 2 lines
                Text(article.headline)
                    .font(AppFonts.subheadline(size: 15))
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                // Reading time
                Text("\(article.readingTimeMinutes) min read")
                    .font(AppFonts.caption(size: 11))
                    .foregroundColor(AppColors.textTertiary)
            }
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - ArticleRowSkeletonView

struct ArticleRowSkeletonView: View {
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "#EDE0D6"))
                .frame(width: 90, height: 72)

            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: "#EDE0D6"))
                    .frame(width: 80, height: 10)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: "#EDE0D6"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 14)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: "#EDE0D6"))
                    .frame(width: 120, height: 14)
            }
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shimmering()
    }
}

#Preview {
    ArticleRowView(article: .preview, isSaved: true)
        .padding(20)
        .background(AppColors.backgroundCream)
}
