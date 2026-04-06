import Foundation

// MARK: - Article

/// Core article model. Maps NewsData.io API fields and is used
/// throughout the app for display and persistence.
struct Article: Identifiable, Codable, Equatable, Hashable {

    // MARK: Stored Properties

    let id: String              // article_id from NewsData.io
    let headline: String        // "made simple" headline (max 52 chars)
    let originalHeadline: String
    let description: String     // Full description text
    let content: String?        // Full article body (if available)
    let imageURL: String?
    let sourceURL: String
    let sourceName: String
    let publishedAt: Date
    let category: [String]

    // MARK: Computed

    var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: publishedAt, relativeTo: Date())
    }

    var readingTimeMinutes: Int {
        let words = (content ?? description).split(separator: " ").count
        return max(1, words / 200)
    }

    // MARK: CodingKeys (maps API snake_case)

    enum CodingKeys: String, CodingKey {
        case id = "article_id"
        case originalHeadline = "title"
        case description
        case content
        case imageURL = "image_url"
        case sourceURL = "link"
        case sourceName = "source_id"
        case publishedAt = "pubDate"
        case category
        // 'headline' is computed/transformed — not decoded from API
        case headline
    }

    // MARK: Custom Decode

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        originalHeadline = try container.decode(String.self, forKey: .originalHeadline)
        description = (try? container.decodeIfPresent(String.self, forKey: .description)) ?? ""
        content = try? container.decodeIfPresent(String.self, forKey: .content)
        imageURL = try? container.decodeIfPresent(String.self, forKey: .imageURL)
        sourceURL = try container.decode(String.self, forKey: .sourceURL)
        sourceName = (try? container.decodeIfPresent(String.self, forKey: .sourceName)) ?? "Unknown"
        category = (try? container.decodeIfPresent([String].self, forKey: .category)) ?? []

        // Parse date string "2024-01-15 12:30:00" → Date
        let dateString = (try? container.decodeIfPresent(String.self, forKey: .publishedAt)) ?? ""
        publishedAt = Article.parseDate(dateString) ?? Date()

        // Headline: if already stored (from Supabase), decode; otherwise use original
        headline = (try? container.decodeIfPresent(String.self, forKey: .headline))
            ?? originalHeadline
    }

    // MARK: Manual Init (used for previews and Supabase reconstruction)

    init(
        id: String,
        headline: String,
        originalHeadline: String,
        description: String,
        content: String? = nil,
        imageURL: String? = nil,
        sourceURL: String,
        sourceName: String,
        publishedAt: Date,
        category: [String] = []
    ) {
        self.id = id
        self.headline = headline
        self.originalHeadline = originalHeadline
        self.description = description
        self.content = content
        self.imageURL = imageURL
        self.sourceURL = sourceURL
        self.sourceName = sourceName
        self.publishedAt = publishedAt
        self.category = category
    }

    // MARK: Helpers

    private static func parseDate(_ string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.date(from: string)
    }

    // MARK: Encode

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(headline, forKey: .headline)
        try container.encode(originalHeadline, forKey: .originalHeadline)
        try container.encode(description, forKey: .description)
        try container.encodeIfPresent(content, forKey: .content)
        try container.encodeIfPresent(imageURL, forKey: .imageURL)
        try container.encode(sourceURL, forKey: .sourceURL)
        try container.encode(sourceName, forKey: .sourceName)
        try container.encode(category, forKey: .category)
        let formatter = ISO8601DateFormatter()
        try container.encode(formatter.string(from: publishedAt), forKey: .publishedAt)
    }
}

// MARK: - NewsData.io Response Envelope

struct NewsDataResponse: Codable {
    let status: String
    let totalResults: Int
    let results: [Article]
    let nextPage: String?
}

// MARK: - Preview Helpers

extension Article {
    static let preview = Article(
        id: "preview-001",
        headline: "This AI startup just raised $40M to build faster chips",
        originalHeadline: "Company X Raises Series B to Expand AI Infrastructure",
        description: "A well-known Silicon Valley startup closed a massive funding round this week.",
        content: "xAI has raised $6 billion and is seeking another $4.3 billion to accelerate large-scale foundation model development.",
        imageURL: "https://picsum.photos/seed/tech1/800/450",
        sourceURL: "https://techcrunch.com",
        sourceName: "TechCrunch",
        publishedAt: Date().addingTimeInterval(-3600),
        category: ["technology"]
    )

    static let previewList: [Article] = [
        Article(
            id: "preview-002",
            headline: "Joby Aviation is teaming up with Delta to create air taxis",
            originalHeadline: "Joby Aviation Partners With Delta and Uber to Create Air Taxis",
            description: "Air taxi service coming to major US airports.",
            imageURL: "https://picsum.photos/seed/tech2/800/450",
            sourceURL: "https://example.com",
            sourceName: "Reuters",
            publishedAt: Date().addingTimeInterval(-7200)
        ),
        Article(
            id: "preview-003",
            headline: "Former OpenAI CTO launches a new AI robotics company",
            originalHeadline: "Former OpenAI CTO Launches Thinking Machines Lab",
            description: "Ex-OpenAI exec steps out to build next-gen AI robots.",
            imageURL: "https://picsum.photos/seed/tech3/800/450",
            sourceURL: "https://example.com",
            sourceName: "Wired",
            publishedAt: Date().addingTimeInterval(-10800)
        ),
        Article(
            id: "preview-004",
            headline: "Apple's first foldable iPhone is expected to launch in 2026",
            originalHeadline: "Apple's First Foldable iPhone Rumored to Come Out in 2026",
            description: "Apple is said to be working on a foldable iPhone for release next year.",
            imageURL: "https://picsum.photos/seed/tech4/800/450",
            sourceURL: "https://example.com",
            sourceName: "Bloomberg",
            publishedAt: Date().addingTimeInterval(-14400)
        )
    ]
}
