import Foundation
import SwiftUI
import Combine

// MARK: - SavedArticlesViewModel

@MainActor
final class SavedArticlesViewModel: ObservableObject {

    // MARK: - Published

    @Published var savedArticles: [Article] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var searchQuery: String = ""
    @Published var isSearchActive: Bool = false

    // MARK: - Private

    private var allSavedArticles: [Article] = []
    private var searchCancellable: AnyCancellable?

    // MARK: - Init

    init() { setupSearchDebounce() }

    // MARK: - Fetch

    func fetchSavedArticles(userID: String) async {
        isLoading = true
        do {
            let saved = try await SupabaseManager.shared.fetchSavedArticles(userID: userID)
            allSavedArticles = saved.map { $0.articleData }
            applySearch()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Save / Unsave

    func unsave(article: Article, userID: String) async {
        // Optimistic remove
        allSavedArticles.removeAll { $0.id == article.id }
        applySearch()

        do {
            try await SupabaseManager.shared.unsaveArticle(articleID: article.id, userID: userID)
        } catch {
            // Restore on failure
            allSavedArticles.insert(article, at: 0)
            applySearch()
            errorMessage = error.localizedDescription
        }
    }

    func isArticleSaved(_ article: Article) -> Bool {
        allSavedArticles.contains { $0.id == article.id }
    }

    // MARK: - Search

    private func setupSearchDebounce() {
        searchCancellable = $searchQuery
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.applySearch()
            }
    }

    private func applySearch() {
        let query = searchQuery.trimmingCharacters(in: .whitespaces).lowercased()
        if query.isEmpty {
            savedArticles = allSavedArticles
        } else {
            savedArticles = allSavedArticles.filter {
                $0.headline.lowercased().contains(query) ||
                $0.sourceName.lowercased().contains(query)
            }
        }
    }

    func clearError() { errorMessage = nil }
}
