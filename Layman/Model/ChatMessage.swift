import Foundation

// MARK: - ChatMessage

struct ChatMessage: Identifiable, Equatable {
    let id: UUID
    let role: MessageRole
    let text: String
    let timestamp: Date
    var isAnimating: Bool

    init(
        id: UUID = UUID(),
        role: MessageRole,
        text: String,
        timestamp: Date = Date(),
        isAnimating: Bool = false
    ) {
        self.id = id
        self.role = role
        self.text = text
        self.timestamp = timestamp
        self.isAnimating = isAnimating
    }
}

// MARK: - MessageRole

enum MessageRole: String, Equatable {
    case bot
    case user
}

// MARK: - Groq API Models

struct GroqRequest: Encodable {
    let model: String
    let messages: [GroqMessage]
    let maxTokens: Int
    let temperature: Double

    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case maxTokens = "max_tokens"
        case temperature
    }
}

struct GroqMessage: Codable {
    let role: String
    let content: String
}

struct GroqResponse: Decodable {
    let choices: [GroqChoice]
}

struct GroqChoice: Decodable {
    let message: GroqMessage
}
