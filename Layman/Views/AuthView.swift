import SwiftUI

// MARK: - AuthView

struct AuthView: View {

    @EnvironmentObject private var authViewModel: AuthViewModel
    @FocusState private var focusedField: AuthField?

    enum AuthField { case email, password, confirmPassword, forgotEmail }

    var body: some View {
        ZStack {
            AppColors.backgroundCream.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    headerSection
                        .padding(.top, 150)
                        .padding(.bottom, 36)

                    // Email confirmation banner
                    if authViewModel.showEmailConfirmationBanner {
                        confirmationBanner
                            .padding(.horizontal, 24)
                            .padding(.bottom, 20)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    formSection
                        .padding(.horizontal, 24)

                    // Forgot password link (only on sign-in)
                    if !authViewModel.isSignUpMode {
                        forgotPasswordLink
                            .padding(.top, 12)
                            .padding(.horizontal, 24)
                    }

                    // Error message
                    if let error = authViewModel.errorMessage {
                        errorBanner(error)
                            .padding(.horizontal, 24)
                            .padding(.top, 12)
                            .transition(.opacity)
                    }

                    actionSection
                        .padding(.horizontal, 24)
                        .padding(.top, 20)

                    toggleModeButton
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                }
            }
        }
        .navigationBarBackButtonHidden(true)  // No back to Welcome after swiping
        .navigationTitle("")
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: authViewModel.showEmailConfirmationBanner)
        .animation(.easeInOut(duration: 0.25), value: authViewModel.errorMessage)
        // Forgot Password sheet
        .sheet(isPresented: $authViewModel.showForgotPassword, onDismiss: {
            authViewModel.forgotPasswordSent = false
            authViewModel.forgotPasswordEmail = ""
            authViewModel.errorMessage = nil
        }) {
            ForgotPasswordSheet()
                .environmentObject(authViewModel)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Layman")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(AppColors.textPrimary)

            Text(authViewModel.isSignUpMode ? "Create your account" : "Welcome back")
                .font(AppFonts.subheadline(size: 16))
                .foregroundColor(AppColors.textSecondary)
        }
    }

    // MARK: - Email Confirmation Banner

    private var confirmationBanner: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "envelope.badge.fill")
                    .font(.system(size: 18))
                    .foregroundColor(AppColors.accentOrange)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Check your email!")
                        .font(AppFonts.subheadline(size: 14))
                        .foregroundColor(AppColors.textPrimary)
                    Text("We sent a confirmation link to \(authViewModel.pendingConfirmationEmail)")
                        .font(AppFonts.caption(size: 12))
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            Button {
                Task { await authViewModel.resendConfirmationEmail() }
            } label: {
                Text("Resend email")
                    .font(AppFonts.button(size: 13))
                    .foregroundColor(AppColors.accentOrange)
                    .underline()
            }
        }
        .padding(16)
        .background(AppColors.accentOrange.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppColors.accentOrange.opacity(0.3), lineWidth: 1))
    }

    // MARK: - Error Banner

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(.red)
            Text(message)
                .font(AppFonts.body(size: 14))
                .foregroundColor(Color(hex: "#7A1A1A"))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(Color.red.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.red.opacity(0.2), lineWidth: 1))
    }

    // MARK: - Form

    private var formSection: some View {
        VStack(spacing: 14) {
            AuthTextField(
                placeholder: "Email address",
                text: $authViewModel.email,
                icon: "envelope",
                keyboardType: .emailAddress,
                isSecure: false
            )
            .focused($focusedField, equals: .email)
            .submitLabel(.next)
            .onSubmit { focusedField = .password }

            AuthTextField(
                placeholder: "Password",
                text: $authViewModel.password,
                icon: "lock",
                keyboardType: .default,
                isSecure: true
            )
            .focused($focusedField, equals: .password)
            .submitLabel(authViewModel.isSignUpMode ? .next : .done)
            .onSubmit {
                if authViewModel.isSignUpMode {
                    focusedField = .confirmPassword
                } else {
                    focusedField = nil
                    Task { await authViewModel.signIn() }
                }
            }

            if authViewModel.isSignUpMode {
                AuthTextField(
                    placeholder: "Confirm password",
                    text: $authViewModel.confirmPassword,
                    icon: "lock.fill",
                    keyboardType: .default,
                    isSecure: true
                )
                .focused($focusedField, equals: .confirmPassword)
                .submitLabel(.done)
                .onSubmit {
                    focusedField = nil
                    Task { await authViewModel.signUp() }
                }
                .transition(.move(edge: .top).combined(with: .opacity))

                // Password hint
                Text("At least 8 characters required")
                    .font(AppFonts.caption(size: 12))
                    .foregroundColor(AppColors.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: authViewModel.isSignUpMode)
    }

    // MARK: - Forgot Password Link

    private var forgotPasswordLink: some View {
        Button {
            authViewModel.forgotPasswordEmail = authViewModel.email
            authViewModel.showForgotPassword = true
        } label: {
            Text("Forgot password?")
                .font(AppFonts.body(size: 14))
                .foregroundColor(AppColors.accentOrange)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    // MARK: - Action Button

    private var actionSection: some View {
        Button {
            focusedField = nil
            authViewModel.errorMessage = nil
            Task {
                if authViewModel.isSignUpMode {
                    await authViewModel.signUp()
                } else {
                    await authViewModel.signIn()
                }
            }
        } label: {
            ZStack {
                if authViewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(authViewModel.isSignUpMode ? "Create Account" : "Sign In")
                        .font(AppFonts.button(size: 16))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(AppColors.accentOrange)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: AppColors.accentOrange.opacity(0.35), radius: 10, x: 0, y: 4)
        }
        .disabled(authViewModel.isLoading)
    }

    // MARK: - Toggle Mode

    private var toggleModeButton: some View {
        Button {
            withAnimation { authViewModel.toggleMode() }
        } label: {
            HStack(spacing: 4) {
                Text(authViewModel.isSignUpMode ? "Already have an account?" : "Don't have an account?")
                    .font(AppFonts.body(size: 14))
                    .foregroundColor(AppColors.textSecondary)

                Text(authViewModel.isSignUpMode ? "Sign In" : "Sign Up")
                    .font(AppFonts.button(size: 14))
                    .foregroundColor(AppColors.accentOrange)
            }
        }
    }
}

// MARK: - ForgotPasswordSheet

struct ForgotPasswordSheet: View {

    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.backgroundCream.ignoresSafeArea()

                VStack(spacing: 0) {
                    if authViewModel.forgotPasswordSent {
                        successContent
                    } else {
                        resetContent
                    }
                }
                .padding(24)
            }
            .navigationTitle("Reset Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundColor(AppColors.accentOrange)
                }
            }
        }
    }

    private var resetContent: some View {
        VStack(spacing: 20) {
            Spacer()

            VStack(spacing: 8) {
                Image(systemName: "key.fill")
                    .font(.system(size: 44))
                    .foregroundColor(AppColors.accentOrange)

                Text("Forgot your password?")
                    .font(AppFonts.headline(size: 22))
                    .foregroundColor(AppColors.textPrimary)

                Text("Enter your email and we'll send you a reset link.")
                    .font(AppFonts.body(size: 14))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 10)
            }

            AuthTextField(
                placeholder: "Email address",
                text: $authViewModel.forgotPasswordEmail,
                icon: "envelope",
                keyboardType: .emailAddress,
                isSecure: false
            )
            .focused($isFocused)

            if let error = authViewModel.errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.red)
                        .font(.system(size: 14))
                    Text(error)
                        .font(AppFonts.caption(size: 13))
                        .foregroundColor(.red)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button {
                isFocused = false
                Task { await authViewModel.sendPasswordReset() }
            } label: {
                ZStack {
                    if authViewModel.isSendingReset {
                        ProgressView().tint(.white)
                    } else {
                        Text("Send Reset Link")
                            .font(AppFonts.button(size: 16))
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(AppColors.accentOrange)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .disabled(authViewModel.isSendingReset)

            Spacer()
        }
    }

    private var successContent: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)

            Text("Email Sent!")
                .font(AppFonts.headline(size: 24))
                .foregroundColor(AppColors.textPrimary)

            Text("Check your inbox for a password reset link. It may take a minute to arrive.")
                .font(AppFonts.body(size: 15))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 10)

            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(AppFonts.button(size: 16))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(AppColors.accentOrange)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            Spacer()
        }
    }
}

// MARK: - AuthTextField

struct AuthTextField: View {

    let placeholder: String
    @Binding var text: String
    let icon: String
    let keyboardType: UIKeyboardType
    let isSecure: Bool

    @State private var isRevealed: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(AppColors.textSecondary)
                .frame(width: 20)

            if isSecure && !isRevealed {
                SecureField(placeholder, text: $text)
                    .font(AppFonts.body(size: 15))
                    .keyboardType(keyboardType)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            } else {
                TextField(placeholder, text: $text)
                    .font(AppFonts.body(size: 15))
                    .keyboardType(keyboardType)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }

            if isSecure {
                Button {
                    isRevealed.toggle()
                } label: {
                    Image(systemName: isRevealed ? "eye.slash" : "eye")
                        .font(.system(size: 15))
                        .foregroundColor(AppColors.textTertiary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(hex: "#E8DDD5"), lineWidth: 1)
        )
    }
}

#Preview {
    NavigationStack {
        AuthView()
            .environmentObject(AuthViewModel())
    }
}
