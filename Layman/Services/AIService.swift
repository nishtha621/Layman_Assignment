import Foundation

// MARK: - AIService

/// Handles all AI interactions via the Groq API (free tier, fast llama3 model).
final class AIService {

    // MARK: - Singleton

    static let shared = AIService()
    private init() {}

    // MARK: - Private

    private let endpoint = "https://api.groq.com/openai/v1/chat/completions"
    private var apiKey: String { AppConfig.groqAPIKey }
    private let model = "llama-3.1-8b-instant"  // Free-tier Groq model

    // MARK: - Headline Simplifier

    func simplifyHeadline(_ originalHeadline: String) async throws -> String {
        let prompt = """
        Rewrite this news headline in casual, everyday language — like texting a friend.
        Rules:
        - Maximum 52 characters
        - 7 to 9 words
        - No jargon or formal business-speak
        - Start with an interesting word (not "A" or "The")
        - Return ONLY the rewritten headline, nothing else

        Original: \(originalHeadline)
        """
        return try await complete(systemPrompt: laymanSystemPrompt, userMessage: prompt, maxTokens: 80)
    }

    // MARK: - Chat Response

    func chatResponse(
        articleContext: String,
        conversationHistory: [ChatMessage],
        userQuestion: String
    ) async throws -> String {
        // Truncate context to prevent exceeding token limits (Groq llama3-8b = 8192 tokens)
        let safeContext = String(articleContext.prefix(600))

        let system = """
        \(laymanSystemPrompt)

        Article the user is reading:
        \(safeContext)

        Answer ONLY about this article. Keep answers to 1–2 short sentences.
        """

        var messages: [GroqMessage] = [GroqMessage(role: "system", content: system)]

        // Include last 4 messages of history to keep context window manageable
        let recentHistory = conversationHistory.filter { !$0.isAnimating }.suffix(4)
        for msg in recentHistory {
            messages.append(GroqMessage(
                role: msg.role == .user ? "user" : "assistant",
                content: msg.text
            ))
        }
        messages.append(GroqMessage(role: "user", content: userQuestion))

        return try await completeWithMessages(messages, maxTokens: 150)
    }

    // MARK: - Suggested Questions

    func generateSuggestedQuestions(for article: Article) async throws -> [String] {
        let prompt = """
        Based on this article, write exactly 3 short questions a regular person would ask. 
        Rules: each question is max 8 words, one per line, no numbering or bullets.

        Article: \(article.headline)
        Summary: \(String(article.description.prefix(300)))
        """
        let raw = try await complete(systemPrompt: laymanSystemPrompt, userMessage: prompt, maxTokens: 120)
        let questions = raw
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "0123456789.-) ")) }
            .filter { $0.count > 5 && !$0.isEmpty }
            .prefix(3)
        return Array(questions)
    }

    // MARK: - Article Summary Cards

    /// Rewrites article content into 3 cards of 2 sentences each.
    func generateContentCards(for article: Article) async throws -> [ContentCard] {
        // Use description as primary source (NewsData.io free tier truncates content heavily)
        let source = (article.content ?? article.description)
        let safeSource = String(source.prefix(1200))  // keep within token budget

        let prompt = """
        You are simplifying a news article into 3 short summary cards for a general audience.
        Write exactly 3 cards. Each card must have exactly 2 sentences in plain, simple English.
        
        Output format — use EXACTLY this structure on separate lines:
        CARD1: [your 2 sentences]
        CARD2: [your 2 sentences]
        CARD3: [your 2 sentences]

        Article headline: \(article.originalHeadline)
        Article content: \(safeSource)
        """
        let raw = try await complete(systemPrompt: laymanSystemPrompt, userMessage: prompt, maxTokens: 400)
        let cards = parseContentCards(from: raw)
        guard !cards.isEmpty else { throw LaymanError.serverError("Could not parse AI cards") }
        return cards
    }

    // MARK: - Private Helpers

    private var laymanSystemPrompt: String {
        "You are Layman — a friendly news explainer. Use plain everyday English. No jargon. Short sentences."
    }

    private func complete(systemPrompt: String, userMessage: String, maxTokens: Int = 256) async throws -> String {
        let messages = [
            GroqMessage(role: "system", content: systemPrompt),
            GroqMessage(role: "user", content: userMessage)
        ]
        return try await completeWithMessages(messages, maxTokens: maxTokens)
    }

    private func completeWithMessages(_ messages: [GroqMessage], maxTokens: Int = 256) async throws -> String {
        let requestBody = GroqRequest(
            model: model,
            messages: messages,
            maxTokens: maxTokens,
            temperature: 0.7
        )

        guard let url = URL(string: endpoint) else { throw LaymanError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 25

        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LaymanError.networkError
        }

        guard httpResponse.statusCode == 200 else {
            // Parse Groq error for helpful debugging
            if let errorJSON = try? JSONDecoder().decode(GroqErrorResponse.self, from: data) {
                throw LaymanError.serverError("Groq: \(errorJSON.error.message)")
            }
            throw LaymanError.serverError("Groq API error \(httpResponse.statusCode)")
        }

        let groqResponse = try JSONDecoder().decode(GroqResponse.self, from: data)
        guard let content = groqResponse.choices.first?.message.content else {
            throw LaymanError.serverError("Empty AI response")
        }
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Card Parsing

    /// Robust parser — finds CARD1/CARD2/CARD3 labels anywhere in the response,
    /// regardless of line order or extra whitespace.
    private func parseContentCards(from raw: String) -> [ContentCard] {
        var cards: [ContentCard] = []

        for i in 1...3 {
            // Match "CARD1:", "Card 1:", "card1:", "CARD 1:" etc.
            let patterns = ["CARD\(i):", "Card \(i):", "CARD \(i):", "card\(i):"]
            for pattern in patterns {
                if let range = raw.range(of: pattern, options: .caseInsensitive) {
                    // Extract text after the label until next CARD label or end
                    let afterLabel = String(raw[range.upperBound...])
                        .trimmingCharacters(in: .whitespacesAndNewlines)

                    // Cut off at the next CARD label
                    var text = afterLabel
                    for j in 1...3 where j != i {
                        let nextPatterns = ["CARD\(j):", "Card \(j):", "CARD \(j):", "card\(j):"]
                        for np in nextPatterns {
                            if let nextRange = text.range(of: np, options: .caseInsensitive) {
                                text = String(text[..<nextRange.lowerBound])
                                    .trimmingCharacters(in: .whitespacesAndNewlines)
                                break
                            }
                        }
                    }

                    if !text.isEmpty && text != "More details coming soon." {
                        cards.append(ContentCard(id: i - 1, text: text))
                        break
                    }
                }
            }
        }

        return cards.sorted { $0.id < $1.id }
    }
}

// MARK: - Groq Error Response

private struct GroqErrorResponse: Decodable {
    struct ErrorDetail: Decodable {
        let message: String
    }
    let error: ErrorDetail
}
