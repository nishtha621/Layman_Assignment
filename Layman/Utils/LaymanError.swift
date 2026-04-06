import Foundation

// MARK: - LaymanError

enum LaymanError: LocalizedError {
    case networkError
    case invalidURL
    case decodingError
    case serverError(String)
    case authError(String)
    case emailNotConfirmed(String)   // Associated email address
    case unknown

    var errorDescription: String? {
        switch self {
        case .networkError:
            return "No internet connection. Please check your network and try again."
        case .invalidURL:
            return "Something went wrong with the request. Please try again."
        case .decodingError:
            return "We had trouble reading the data. Please try again."
        case .serverError(let message):
            return message
        case .authError(let message):
            return message
        case .emailNotConfirmed(let email):
            return "Please confirm your email before signing in. We sent a link to \(email)."
        case .unknown:
            return "An unexpected error occurred. Please try again."
        }
    }
}
