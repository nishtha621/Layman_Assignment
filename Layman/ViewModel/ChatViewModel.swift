import Foundation
import SwiftUI
import Combine

// MARK: - ChatViewModel

@MainActor
final class ChatViewModel: ObservableObject {

    // MARK: - Published

    @Published var messages: [ChatMessage] = []
    @Published var suggestedQuestions: [String] = []
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    @Published var isLoadingSuggestions: Bool = false
    @Published var errorMessage: String?

    // MARK: - Article Context

    let article: Article

    // MARK: - Init

    init(article: Article) {
        self.article = article
        setupInitialMessage()
        Task {
            await loadSuggestedQuestions()
        }
    }

    // MARK: - Initial Bot Message

    private func setupInitialMessage() {
        let welcome = ChatMessage(
            role: .bot,
            text: "Hi, I'm Layman! What can I answer for you?"
        )
        messages = [welcome]
    }

    // MARK: - Load Question Suggestions

    func loadSuggestedQuestions() async {
        isLoadingSuggestions = true
        do {
            suggestedQuestions = try await AIService.shared.generateSuggestedQuestions(for: article)
        } catch {
            // Fallback: generic questions based on article category
            suggestedQuestions = [
                "What does this mean for regular people?",
                "Why is this a big deal?",
                "Who is most affected by this?"
            ]
        }
        isLoadingSuggestions = false
    }

    // MARK: - Send Message

    func sendMessage() async {
        let question = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty, !isLoading else { return }

        inputText = ""
        await send(question: question)
    }

    func sendSuggestedQuestion(_ question: String) async {
        guard !isLoading else { return }
        // Remove tapped suggestion from chips
        suggestedQuestions.removeAll { $0 == question }
        await send(question: question)
    }

    // MARK: - Private

    private func send(question: String) async {
        // Add user message
        let userMessage = ChatMessage(role: .user, text: question)
        withAnimation { messages.append(userMessage) }

        // Add loading placeholder
        let loadingMessage = ChatMessage(role: .bot, text: "...", isAnimating: true)
        isLoading = true
        withAnimation { messages.append(loadingMessage) }

        do {
            let articleContext = "\(article.headline)\n\n\(article.description)\n\n\(article.content ?? "")"
            let response = try await AIService.shared.chatResponse(
                articleContext: articleContext,
                conversationHistory: messages.filter { !$0.isAnimating },
                userQuestion: question
            )

            // Replace loading placeholder with real response
            if let lastIndex = messages.indices.last {
                messages[lastIndex] = ChatMessage(role: .bot, text: response)
            }
        } catch {
            if let lastIndex = messages.indices.last {
                messages[lastIndex] = ChatMessage(
                    role: .bot,
                    text: "Sorry, I had trouble answering that. Try again!"
                )
            }
        }
        isLoading = false
    }
}
