import Foundation
import Auth   // Supabase Auth module

// MARK: - AppUser

/// Represents an authenticated user. Wraps Supabase user data.
struct AppUser: Codable, Equatable {
    let id: String
    let email: String
    var displayName: String?
    var avatarURL: String?
    let createdAt: Date

    var initials: String {
        if let name = displayName, !name.isEmpty {
            let parts = name.split(separator: " ")
            let letters = parts.prefix(2).compactMap { $0.first?.uppercased() }
            return letters.joined()
        }
        return String(email.prefix(2)).uppercased()
    }

    var firstName: String {
        displayName?.split(separator: " ").first.map(String.init)
            ?? email.components(separatedBy: "@").first
            ?? "User"
    }

    // MARK: - SDK Mapping

    /// Initialises from the Supabase SDK `User` type.
    init(from user: Auth.User) {
        self.id = user.id.uuidString
        self.email = user.email ?? ""
        self.createdAt = user.createdAt
        self.avatarURL = nil

        // `userMetadata` is [String: AnyJSON]; use `.stringValue` to extract strings
        self.displayName = user.userMetadata["full_name"]?.stringValue
            ?? user.userMetadata["name"]?.stringValue
    }
}

// MARK: - AuthState

enum AuthState: Equatable {
    case loading
    case unauthenticated
    case authenticated
}
