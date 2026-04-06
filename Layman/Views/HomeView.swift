import SwiftUI

// MARK: - HomeView

struct HomeView: View {

    @StateObject private var vm = HomeViewModel()
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var savedVM: SavedArticlesViewModel
    @State private var selectedArticle: Article?

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.backgroundCream.ignoresSafeArea()

                if vm.isLoadingFeatured && vm.featuredArticles.isEmpty {
                    loadingView
                } else {
                    contentScrollView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .navigationDestination(item: $selectedArticle) { article in
                ArticleDetailView(article: article)
            }
        }
        .task { await vm.loadArticles() }
        .refreshable { await vm.refreshArticles() }
    }

    // MARK: - Content

    private var contentScrollView: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0, pinnedViews: []) {
                // Search bar (visible when search is active)
                if vm.isSearchActive {
                    searchBarView
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                // Featured Carousel
                if !vm.isSearchActive {
                    featuredCarousel
                        .padding(.top, 8)
                }

                // Section header
                sectionHeader
                    .padding(.horizontal, 20)
                    .padding(.top, vm.isSearchActive ? 8 : 24)
                    .padding(.bottom, 12)

                // Articles list
                articlesListView
                    .padding(.bottom, 100) // tab bar clearance
            }
        }
        .animation(.easeInOut(duration: 0.25), value: vm.isSearchActive)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text("Layman")
                .font(AppFonts.logo(size: 24))
                .foregroundColor(AppColors.textPrimary)
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                withAnimation { vm.isSearchActive.toggle() }
                if !vm.isSearchActive { vm.searchQuery = "" }
            } label: {
                Image(systemName: vm.isSearchActive ? "xmark" : "magnifyingglass")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(AppColors.textPrimary)
            }
        }
    }

    // MARK: - Search Bar

    private var searchBarView: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15))
                .foregroundColor(AppColors.textTertiary)

            TextField("Search stories...", text: $vm.searchQuery)
                .font(AppFonts.body(size: 15))
                .autocorrectionDisabled()

            if !vm.searchQuery.isEmpty {
                Button { vm.searchQuery = "" } label: {
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

    // MARK: - Featured Carousel

    private var featuredCarousel: some View {
        VStack(spacing: 12) {
            if vm.isLoadingFeatured {
                CarouselSkeletonView()
            } else if vm.featuredArticles.isEmpty {
                EmptyStateView(
                    icon: "newspaper",
                    title: "No featured stories",
                    message: "Pull down to refresh"
                )
                .frame(height: 220)
            } else {
                FeaturedCarouselView(
                    articles: vm.featuredArticles,
                    currentIndex: $vm.currentCarouselIndex,
                    onTap: { article in selectedArticle = article }
                )
            }

            // Page dots
            if !vm.featuredArticles.isEmpty {
                PageDotsView(
                    count: vm.featuredArticles.count,
                    current: vm.currentCarouselIndex
                )
            }
        }
    }

    // MARK: - Section Header

    private var sectionHeader: some View {
        HStack {
            Text(vm.isSearchActive && !vm.searchQuery.isEmpty ? "Search Results" : "Today's Picks")
                .font(AppFonts.headline(size: 20))
                .foregroundColor(AppColors.textPrimary)

            Spacer()

            if vm.isSearching {
                ProgressView()
                    .scaleEffect(0.8)
            } else if vm.isSearchActive && !vm.searchQuery.isEmpty {
                Text("\(vm.displayedArticles.count) stories")
                    .font(AppFonts.caption(size: 13))
                    .foregroundColor(AppColors.textTertiary)
            }
        }
    }

    // MARK: - Articles List

    private var articlesListView: some View {
        LazyVStack(spacing: 0) {
            let articles = vm.displayedArticles
            if articles.isEmpty && !vm.isLoadingPicks {
                EmptyStateView(
                    icon: "newspaper",
                    title: vm.isSearchActive ? "No results found" : "No stories yet",
                    message: vm.isSearchActive ? "Try a different search" : "Pull to refresh"
                )
                .padding(.top, 40)
            } else {
                ForEach(articles) { article in
                    ArticleRowView(
                        article: article,
                        isSaved: savedVM.isArticleSaved(article)
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                    .contentShape(Rectangle())
                    .onTapGesture { selectedArticle = article }
                    .task {
                        await vm.loadMorePicksIfNeeded(currentArticle: article)
                    }
                }

                if vm.isLoadingPicks {
                    ProgressView()
                        .padding(.vertical, 20)
                }
            }
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: 20) {
            CarouselSkeletonView()
                .padding(.top, 8)
            ForEach(0..<4, id: \.self) { _ in
                ArticleRowSkeletonView()
                    .padding(.horizontal, 20)
            }
            Spacer()
        }
    }
}

// MARK: - Page Dots

struct PageDotsView: View {
    let count: Int
    let current: Int

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<count, id: \.self) { i in
                Capsule()
                    .fill(i == current ? AppColors.accentOrange : Color(hex: "#D4C4B8"))
                    .frame(width: i == current ? 18 : 6, height: 6)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: current)
            }
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AuthViewModel())
        .environmentObject(SavedArticlesViewModel())
}
