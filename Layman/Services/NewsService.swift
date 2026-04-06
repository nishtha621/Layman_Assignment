import Foundation

// MARK: - NewsService

/// Fetches business/tech/startup articles from NewsData.io
/// and transforms headlines into conversational layman's terms via Groq AI.
final class NewsService {

    // MARK: - Singleton

    static let shared = NewsService()
    private init() {}

    // MARK: - Private

    private let baseURL = "https://newsdata.io/api/1/news"
    private var apiKey: String { AppConfig.newsAPIKey }

    // MARK: - Fetch Featured Articles (Carousel)

    func fetchFeaturedArticles() async throws -> [Article] {
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "apikey", value: apiKey),
            URLQueryItem(name: "category", value: "technology,business"),
            URLQueryItem(name: "language", value: "en"),
            URLQueryItem(name: "image", value: "1"),  // only articles with images
            URLQueryItem(name: "size", value: "5")
        ]
        let articles = try await fetch(url: components.url!)
        return await simplifyHeadlines(for: articles)
    }

    // MARK: - Fetch Today's Picks

    func fetchTodaysPicks(nextPage: String? = nil) async throws -> (articles: [Article], nextPage: String?) {
        var components = URLComponents(string: baseURL)!
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "apikey", value: apiKey),
            URLQueryItem(name: "category", value: "technology,business,science"),
            URLQueryItem(name: "language", value: "en"),
            URLQueryItem(name: "size", value: "10")
        ]
        if let page = nextPage {
            queryItems.append(URLQueryItem(name: "page", value: page))
        }
        components.queryItems = queryItems

        let response = try await fetchRaw(url: components.url!)
        let simplified = await simplifyHeadlines(for: response.results)
        return (articles: simplified, nextPage: response.nextPage)
    }

    // MARK: - Search Articles

    func searchArticles(query: String) async throws -> [Article] {
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "apikey", value: apiKey),
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "language", value: "en"),
            URLQueryItem(name: "size", value: "20")
        ]
        let articles = try await fetch(url: components.url!)
        return await simplifyHeadlines(for: articles)
    }

    // MARK: - AI Headline Simplification

    /// Concurrently rewrites all article headlines to casual layman-style language using Groq AI.
    /// Falls back to originalHeadline silently if AI is unavailable or rate-limited.
    private func simplifyHeadlines(for articles: [Article]) async -> [Article] {
        guard !articles.isEmpty else { return articles }

        return await withTaskGroup(of: (Int, Article).self) { group in
            for (index, article) in articles.enumerated() {
                group.addTask {
                    if let simplified = try? await AIService.shared.simplifyHeadline(article.originalHeadline),
                       !simplified.isEmpty {
                        return (index, Article(
                            id: article.id,
                            headline: simplified,
                            originalHeadline: article.originalHeadline,
                            description: article.description,
                            content: article.content,
                            imageURL: article.imageURL,
                            sourceURL: article.sourceURL,
                            sourceName: article.sourceName,
                            publishedAt: article.publishedAt,
                            category: article.category
                        ))
                    }
                    return (index, article) // fallback: original
                }
            }

            var results = articles
            for await (index, article) in group {
                results[index] = article
            }
            return results
        }
    }

    // MARK: - Private Fetch Helpers

    private func fetch(url: URL) async throws -> [Article] {
        let response = try await fetchRaw(url: url)
        return response.results
    }

    private func fetchRaw(url: URL) async throws -> NewsDataResponse {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 15

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LaymanError.networkError
        }
        guard httpResponse.statusCode == 200 else {
            throw LaymanError.serverError("NewsData.io HTTP \(httpResponse.statusCode)")
        }

        let decoder = JSONDecoder()
        let newsResponse = try decoder.decode(NewsDataResponse.self, from: data)

        if newsResponse.status != "success" {
            throw LaymanError.serverError("NewsData.io returned non-success status")
        }

        return newsResponse
    }
}
