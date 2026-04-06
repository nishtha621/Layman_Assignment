import Foundation

// MARK: - ContentCard

/// Represents one of the 3 swipeable summary cards on the Article Detail screen.
/// Each card contains exactly 2 sentences, 28–35 words, designed to fill 6 lines.
struct ContentCard: Identifiable, Equatable {
    let id: Int          // 0, 1, 2
    let text: String     // 2 sentences, 28–35 words

    /// Splits the text into two sentences for display
    var sentences: [String] {
        // Split on ". " boundaries but keep the period
        let raw = text.components(separatedBy: ". ")
        guard raw.count >= 2 else { return [text] }
        return raw.enumerated().map { index, sentence in
            index < raw.count - 1 ? sentence + "." : sentence
        }
    }
}

// MARK: - Article Content Cards Generator

extension Article {
    /// Derives 3 content cards from the article's content or description.
    /// In production this is pre-processed by the AI during article ingestion.
    var contentCards: [ContentCard] {
        let source = content ?? description
        let sentences = source
            .components(separatedBy: ". ")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { $0.count > 10 }

        // Partition sentences into 3 roughly equal groups
        let chunkSize = max(1, sentences.count / 3)
        var cards: [ContentCard] = []

        for i in 0..<3 {
            let start = i * chunkSize
            let end = min(start + chunkSize, sentences.count)
            guard start < sentences.count else {
                cards.append(ContentCard(id: i, text: "More details coming soon."))
                continue
            }
            let chunk = sentences[start..<end]
                .prefix(2)
                .joined(separator: ". ")
            let cardText = chunk.hasSuffix(".") ? chunk : chunk + "."
            cards.append(ContentCard(id: i, text: cardText))
        }

        return cards.count == 3 ? cards : (0..<3).map { ContentCard(id: $0, text: description) }
    }
}
