import SwiftUI

// MARK: - SavedView

struct SavedView: View {

    @EnvironmentObject private var savedVM: SavedArticlesViewModel
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var selectedArticle: Article?
    @State private var searchText: String = ""
    @State private var isSearchVisible: Bool = false

    private var displayedArticles: [Article] {
        guard isSearchVisible && !searchText.isEmpty else { return savedVM.savedArticles }
        return savedVM.savedArticles.filter {
            $0.headline.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.backgroundCream.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Inline search bar drops in below nav
                    if isSearchVisible {
                        searchBar
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                            .padding(.bottom, 8)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    content
                }
                .animation(.easeInOut(duration: 0.22), value: isSearchVisible)
            }
            // Large title "Saved" left-aligned — matches prototype
            .navigationTitle("Saved")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        withAnimation { isSearchVisible.toggle() }
                        if !isSearchVisible { searchText = "" }
                    } label: {
                        Image(systemName: isSearchVisible ? "xmark" : "magnifyingglass")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(AppColors.textPrimary)
                    }
                }
            }
            .navigationDestination(item: $selectedArticle) { article in
                ArticleDetailView(article: article)
            }
        }
        .task {
            guard let userID = authViewModel.currentUser?.id else { return }
            await savedVM.fetchSavedArticles(userID: userID)
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15))
                .foregroundColor(AppColors.textTertiary)

            TextField("Search saved stories...", text: $searchText)
                .font(AppFonts.body(size: 15))
                .autocorrectionDisabled()

            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppColors.textTertiary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#E8DDD5"), lineWidth: 1))
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if savedVM.isLoading && savedVM.savedArticles.isEmpty {
            loadingView
        } else if displayedArticles.isEmpty {
            emptyState
        } else {
            articleList
        }
    }

    // MARK: - Article List — matches prototype: image + headline only

    private var articleList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(displayedArticles) { article in
                    SavedArticleRow(article: article)
                        .contentShape(Rectangle())
                        .onTapGesture { selectedArticle = article }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                guard let userID = authViewModel.currentUser?.id else { return }
                                Task { await savedVM.unsave(article: article, userID: userID) }
                            } label: {
                                Label("Remove", systemImage: "bookmark.slash")
                            }
                        }
                }
            }
            .padding(.bottom, 100)
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: 0) {
            ForEach(0..<6, id: \.self) { _ in
                SavedArticleRowSkeleton()
            }
            Spacer()
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "bookmark")
                .font(.system(size: 48))
                .foregroundColor(AppColors.textTertiary)
            Text(searchText.isEmpty ? "Nothing saved yet" : "No results found")
                .font(AppFonts.headline(size: 18))
                .foregroundColor(AppColors.textPrimary)
            Text(searchText.isEmpty
                 ? "Tap the bookmark on any story to save it here"
                 : "Try searching for something else")
                .font(AppFonts.body(size: 14))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }
}

// MARK: - SavedArticleRow
// Exactly matches the prototype: rounded thumbnail on left + headline text only

struct SavedArticleRow: View {

    let article: Article

    var body: some View {
        HStack(spacing: 14) {
            // Thumbnail — rounded square, matches prototype
            AsyncImageView(urlString: article.imageURL)
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            // Headline only — no source/date/description
            Text(article.headline)
                .font(AppFonts.subheadline(size: 15))
                .foregroundColor(AppColors.textPrimary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(hex: "#F0E8DF"))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 16)
        .padding(.vertical, 5)
    }
}

// MARK: - SavedArticleRowSkeleton

struct SavedArticleRowSkeleton: View {
    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(hex: "#EDE0D6"))
                .frame(width: 72, height: 72)

            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: "#EDE0D6"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 13)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: "#EDE0D6"))
                    .frame(width: 140)
                    .frame(height: 13)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(hex: "#F0E8DF"))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 16)
        .padding(.vertical, 5)
        .shimmering()
    }
}

#Preview {
    SavedView()
        .environmentObject(SavedArticlesViewModel())
        .environmentObject(AuthViewModel())
}
