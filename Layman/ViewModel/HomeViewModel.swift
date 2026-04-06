import Foundation
import SwiftUI
import Combine

// MARK: - HomeViewModel

@MainActor
final class HomeViewModel: ObservableObject {

    // MARK: - Published

    @Published var featuredArticles: [Article] = []
    @Published var todaysPicks: [Article] = []
    @Published var searchResults: [Article] = []
    @Published var isLoadingFeatured: Bool = false
    @Published var isLoadingPicks: Bool = false
    @Published var isSearching: Bool = false
    @Published var errorMessage: String?
    @Published var searchQuery: String = ""
    @Published var isSearchActive: Bool = false
    @Published var currentCarouselIndex: Int = 0

    // MARK: - Pagination

    private var nextPage: String?
    private var canLoadMore: Bool { nextPage != nil }

    // MARK: - Debounce

    private var searchCancellable: AnyCancellable?

    // MARK: - Init

    init() {
        setupSearchDebounce()
    }

    // MARK: - Load Articles

    func loadArticles() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadFeaturedArticles() }
            group.addTask { await self.loadTodaysPicks() }
        }
    }

    func refreshArticles() async {
        nextPage = nil
        todaysPicks = []
        await loadArticles()
    }

    // MARK: - Featured Carousel

    private func loadFeaturedArticles() async {
        isLoadingFeatured = true
        do {
            featuredArticles = try await NewsService.shared.fetchFeaturedArticles()
        } catch {
            // Non-critical — don't surface to user if Today's Picks loaded
            if todaysPicks.isEmpty {
                errorMessage = error.localizedDescription
            }
        }
        isLoadingFeatured = false
    }

    // MARK: - Today's Picks

    private func loadTodaysPicks() async {
        isLoadingPicks = true
        do {
            let result = try await NewsService.shared.fetchTodaysPicks()
            todaysPicks = result.articles
            nextPage = result.nextPage
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoadingPicks = false
    }

    func loadMorePicksIfNeeded(currentArticle article: Article) async {
        guard let lastArticle = todaysPicks.last,
              lastArticle.id == article.id,
              canLoadMore,
              !isLoadingPicks else { return }

        isLoadingPicks = true
        do {
            let result = try await NewsService.shared.fetchTodaysPicks(nextPage: nextPage)
            todaysPicks.append(contentsOf: result.articles)
            nextPage = result.nextPage
        } catch {
            // Silent pagination failure — user can retry by scrolling
        }
        isLoadingPicks = false
    }

    // MARK: - Search

    private func setupSearchDebounce() {
        searchCancellable = $searchQuery
            .debounce(for: .milliseconds(400), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                guard let self else { return }
                if query.isEmpty {
                    self.searchResults = []
                    self.isSearching = false
                } else {
                    Task { await self.performSearch(query: query) }
                }
            }
    }

    private func performSearch(query: String) async {
        isSearching = true
        do {
            searchResults = try await NewsService.shared.searchArticles(query: query)
        } catch {
            searchResults = []
        }
        isSearching = false
    }

    // MARK: - Helpers

    func clearError() { errorMessage = nil }

    var displayedArticles: [Article] {
        isSearchActive && !searchQuery.isEmpty ? searchResults : todaysPicks
    }
}
