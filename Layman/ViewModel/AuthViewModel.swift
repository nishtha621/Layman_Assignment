import Foundation
import SwiftUI
import Combine
import Auth
import Supabase

// MARK: - AuthViewModel

@MainActor
final class AuthViewModel: ObservableObject {

    // MARK: - Published — Auth State

    @Published var authState: AuthState = .loading
    @Published var currentUser: AppUser?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // MARK: - Published — Form Fields

    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var isSignUpMode: Bool = false

    // MARK: - Published — Special States

    @Published var showEmailConfirmationBanner: Bool = false
    @Published var pendingConfirmationEmail: String = ""

    @Published var showForgotPassword: Bool = false
    @Published var forgotPasswordEmail: String = ""
    @Published var forgotPasswordSent: Bool = false
    @Published var isSendingReset: Bool = false

    // MARK: - Init

    init() {
        // Quick synchronous check — SDK restores session from Keychain on init
        if let sdkUser = SupabaseManager.shared.client.auth.currentUser {
            currentUser = AppUser(from: sdkUser)
            authState = .authenticated
        } else {
            authState = .unauthenticated
        }
        // Then listen for auth state changes (token refresh, sign-out from another device, etc.)
        Task { await listenForAuthChanges() }
    }

    // MARK: - Auth State Listener

    /// Subscribes to the SDK's auth state stream — handles token refresh, sign-out, etc.
    private func listenForAuthChanges() async {
        for await (event, session) in SupabaseManager.shared.client.auth.authStateChanges {
            switch event {
            case .initialSession, .signedIn, .tokenRefreshed:
                if let user = session?.user {
                    currentUser = AppUser(from: user)
                    authState = .authenticated
                } else {
                    authState = .unauthenticated
                }
            case .signedOut, .userDeleted:
                currentUser = nil
                authState = .unauthenticated
            default:
                break
            }
        }
    }

    // MARK: - Legacy Session Check (kept for manual refresh)

    func checkExistingSession() async {
        if let user = await SupabaseManager.shared.currentUser() {
            currentUser = user
            authState = .authenticated
        } else {
            authState = .unauthenticated
        }
    }

    // MARK: - Sign Up

    func signUp() async {
        guard validateSignUpForm() else { return }
        isLoading = true
        errorMessage = nil
        showEmailConfirmationBanner = false

        do {
            let user = try await SupabaseManager.shared.signUp(email: email, password: password)
            currentUser = user
            authState = .authenticated
        } catch LaymanError.emailNotConfirmed(let email) {
            // Supabase requires email confirmation — tell the user clearly
            pendingConfirmationEmail = email
            showEmailConfirmationBanner = true
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Sign In

    func signIn() async {
        guard validateSignInForm() else { return }
        isLoading = true
        errorMessage = nil
        showEmailConfirmationBanner = false

        do {
            let user = try await SupabaseManager.shared.signIn(email: email, password: password)
            currentUser = user
            authState = .authenticated
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Sign Out

    func signOut() async {
        isLoading = true
        try? await SupabaseManager.shared.signOut()
        currentUser = nil
        email = ""
        password = ""
        confirmPassword = ""
        forgotPasswordEmail = ""
        forgotPasswordSent = false
        showEmailConfirmationBanner = false
        authState = .unauthenticated
        isLoading = false
    }

    // MARK: - Forgot Password

    func sendPasswordReset() async {
        let trimmedEmail = forgotPasswordEmail.trimmingCharacters(in: .whitespaces)
        guard !trimmedEmail.isEmpty else {
            errorMessage = "Please enter your email address."
            return
        }
        guard trimmedEmail.contains("@"), trimmedEmail.contains(".") else {
            errorMessage = "Please enter a valid email address."
            return
        }

        isSendingReset = true
        errorMessage = nil
        do {
            try await SupabaseManager.shared.resetPassword(email: trimmedEmail)
            forgotPasswordSent = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isSendingReset = false
    }

    // MARK: - Resend Confirmation

    func resendConfirmationEmail() async {
        guard !pendingConfirmationEmail.isEmpty else { return }
        do {
            try await SupabaseManager.shared.resendConfirmation(email: pendingConfirmationEmail)
        } catch {
            // Silent — already showed the banner
        }
    }

    // MARK: - Validation

    private func validateSignInForm() -> Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        guard !trimmedEmail.isEmpty else {
            errorMessage = "Please enter your email address."
            return false
        }
        guard trimmedEmail.contains("@"), trimmedEmail.contains(".") else {
            errorMessage = "Please enter a valid email address."
            return false
        }
        guard !password.isEmpty else {
            errorMessage = "Please enter your password."
            return false
        }
        return true
    }

    private func validateSignUpForm() -> Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        guard !trimmedEmail.isEmpty else {
            errorMessage = "Please enter your email address."
            return false
        }
        guard trimmedEmail.contains("@"), trimmedEmail.contains(".") else {
            errorMessage = "Please enter a valid email address."
            return false
        }
        guard password.count >= 8 else {
            errorMessage = "Password must be at least 8 characters."
            return false
        }
        guard password == confirmPassword else {
            errorMessage = "Passwords don't match. Please check and try again."
            return false
        }
        return true
    }

    // MARK: - Helpers

    func clearError() {
        errorMessage = nil
    }

    func toggleMode() {
        isSignUpMode.toggle()
        errorMessage = nil
        password = ""
        confirmPassword = ""
        showEmailConfirmationBanner = false
        forgotPasswordSent = false
    }
}
