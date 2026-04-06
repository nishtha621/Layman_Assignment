import Foundation
import Supabase

// MARK: - SupabaseManager

/// Thin wrapper around the official Supabase Swift SDK.
/// The SDK handles session persistence (Keychain), token refresh, and RLS automatically.
final class SupabaseManager {

    // MARK: - Singleton

    static let shared = SupabaseManager()

    // MARK: - SDK Client (public so Views/VMs can use postgrest builder directly if needed)

    let client: SupabaseClient

    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: AppConfig.supabaseURL)!,
            supabaseKey: AppConfig.supabaseAnonKey
        )
    }

    // MARK: - Current User

    /// Returns the cached user from the persisted session — no network call.
    /// The SDK restores the session from Keychain on init, so this is safe to call at launch.
    func currentUser() async -> AppUser? {
        guard let user = client.auth.currentUser else { return nil }
        return AppUser(from: user)
    }

    // MARK: - Sign Up

    /// Signs up a new user.
    /// - Throws `LaymanError.emailNotConfirmed` when Supabase requires email confirmation.
    func signUp(email: String, password: String) async throws -> AppUser {
        do {
            let response = try await client.auth.signUp(email: email, password: password)
            // `AuthResponse` is an enum: .session(Session) or .user(User)
            // If email confirmation is required Supabase returns .user (no session)
            if response.session == nil {
                throw LaymanError.emailNotConfirmed(email)
            }
            return AppUser(from: response.user)
        } catch let error as AuthError {
            throw LaymanError.serverError(authErrorMessage(error))
        }
    }

    // MARK: - Sign In

    func signIn(email: String, password: String) async throws -> AppUser {
        do {
            let session = try await client.auth.signIn(email: email, password: password)
            return AppUser(from: session.user)
        } catch let error as AuthError {
            throw LaymanError.serverError(authErrorMessage(error))
        }
    }

    // MARK: - Sign Out

    func signOut() async throws {
        try await client.auth.signOut()
    }

    // MARK: - Forgot Password

    func resetPassword(email: String) async throws {
        do {
            try await client.auth.resetPasswordForEmail(email)
        } catch let error as AuthError {
            throw LaymanError.serverError(authErrorMessage(error))
        }
    }

    // MARK: - Resend Confirmation

    func resendConfirmation(email: String) async throws {
        try await client.auth.resend(email: email, type: .signup)
    }

    // MARK: - Saved Articles

    func fetchSavedArticles(userID: String) async throws -> [SavedArticle] {
        let articles: [SavedArticle] = try await client
            .from("saved_articles")
            .select()
            .eq("user_id", value: userID)
            .order("saved_at", ascending: false)
            .execute()
            .value
        return articles
    }

    func saveArticle(_ article: Article, userID: String) async throws {
        let payload = SavedArticleInsert(
            userID: userID,
            articleID: article.id,
            articleData: article
        )
        try await client
            .from("saved_articles")
            .insert(payload)
            .execute()
    }

    func unsaveArticle(articleID: String, userID: String) async throws {
        try await client
            .from("saved_articles")
            .delete()
            .eq("article_id", value: articleID)
            .eq("user_id", value: userID)
            .execute()
    }

    // MARK: - Error Mapping

    /// Converts SDK `AuthError` to a user-friendly string.
    private func authErrorMessage(_ error: AuthError) -> String {
        let raw = error.localizedDescription.lowercased()

        if raw.contains("already registered") || raw.contains("user already") {
            return "An account with this email already exists. Try signing in."
        } else if raw.contains("invalid login") || raw.contains("invalid credentials") || raw.contains("invalid_credentials") {
            return "Wrong email or password. Please try again."
        } else if raw.contains("email not confirmed") || raw.contains("email_not_confirmed") {
            return "Your email hasn't been confirmed yet. Check your inbox."
        } else if raw.contains("too many requests") || raw.contains("rate limit") {
            return "Too many attempts. Please wait a moment and try again."
        } else if raw.contains("network") || raw.contains("connection") {
            return "No internet connection. Please check your network."
        }
        return error.localizedDescription
    }
}
