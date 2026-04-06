import Foundation

// MARK: - SavedArticle

/// Represents a bookmarked article persisted in Supabase.
/// Table: saved_articles
/// Columns: id (uuid), user_id (uuid), article_id (text), article_data (jsonb), saved_at (timestamp)
struct SavedArticle: Identifiable, Codable, Equatable {

    let id: String          // Supabase row UUID
    let userID: String
    let articleID: String
    let articleData: Article
    let savedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case articleID = "article_id"
        case articleData = "article_data"
        case savedAt = "saved_at"
    }
}

// MARK: - Supabase Insert Payload

/// Lightweight struct used when inserting a new saved article row
struct SavedArticleInsert: Encodable {
    let userID: String
    let articleID: String
    let articleData: Article

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case articleID = "article_id"
        case articleData = "article_data"
    }
}
