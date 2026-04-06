import Foundation
import SwiftUI
import Combine

// MARK: - ArticleDetailViewModel

@MainActor
final class ArticleDetailViewModel: ObservableObject {

    // MARK: - Published

    @Published var contentCards: [ContentCard] = []
    @Published var currentCardIndex: Int = 0
    @Published var isLoadingCards: Bool = true
    @Published var cardLoadFailed: Bool = false
    @Published var showSafariSheet: Bool = false
    @Published var showShareSheet: Bool = false

    // MARK: - Article

    let article: Article

    // MARK: - Init

    init(article: Article) {
        self.article = article
        Task { await loadAICards() }
    }

    // MARK: - Load AI-Generated Content Cards

    func loadAICards() async {
        isLoadingCards = true
        cardLoadFailed = false

        do {
            let cards = try await AIService.shared.generateContentCards(for: article)
            // Only accept if AI returned exactly 3 valid cards
            if cards.count == 3 && cards.allSatisfy({ !$0.text.isEmpty }) {
                contentCards = cards
            } else {
                contentCards = makeFallbackCards()
            }
        } catch {
            // Silently fall back to computed cards from description
            contentCards = makeFallbackCards()
            cardLoadFailed = true
        }
        isLoadingCards = false
    }

    // MARK: - Retry AI Cards

    func retryAICards() async {
        contentCards = []
        await loadAICards()
    }

    // MARK: - Fallback Card Builder

    /// When AI fails or throttles, build intelligent fallback cards from article description/content.
    /// Always produces 3 readable cards — never shows "More details coming soon."
    private func makeFallbackCards() -> [ContentCard] {
        let source = (article.content ?? article.description)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Split into sentences
        var sentences = source
            .components(separatedBy: ". ")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { $0.count > 8 }

        // If we have enough sentences, take 2 per card
        if sentences.count >= 6 {
            return [
                ContentCard(id: 0, text: sentences[0] + ". " + sentences[1] + "."),
                ContentCard(id: 1, text: sentences[2] + ". " + sentences[3] + "."),
                ContentCard(id: 2, text: sentences[4] + ". " + sentences[5] + ".")
            ]
        } else if sentences.count >= 3 {
            // 1 sentence per card
            return sentences.prefix(3).enumerated().map { i, s in
                ContentCard(id: i, text: s.hasSuffix(".") ? s : s + ".")
            }
        } else {
            // Very short article — repeat with different framing using headline + description
            let headline = article.originalHeadline
            let description = article.description
            return [
                ContentCard(id: 0, text: "Here's what happened: \(description)"),
                ContentCard(id: 1, text: "The story: \(headline)."),
                ContentCard(id: 2, text: "Want the full story? Tap 'Read Full Article' to learn more.")
            ]
        }
    }

    // MARK: - Actions

    func openOriginalArticle() {
        showSafariSheet = true
    }

    func openShareSheet() {
        showShareSheet = true
    }

    var originalURL: URL? {
        URL(string: article.sourceURL)
    }

    var shareItems: [Any] {
        [article.headline, article.sourceURL].compactMap { $0 }
    }
}
