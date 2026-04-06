import SwiftUI
import StoreKit
import UserNotifications

// MARK: - ProfileView

struct ProfileView: View {

    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var savedVM: SavedArticlesViewModel
    @State private var showLogoutConfirm: Bool = false
    @State private var readingStreak: Int = 0
    @State private var showNotificationsAlert: Bool = false
    @State private var showLanguageSheet: Bool = false
    @State private var showPrivacyPolicy: Bool = false
    @State private var showMailError: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.backgroundCream.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        avatarSection
                            .padding(.top, 32)

                        statsSection

                        settingsSection

                        logoutButton
                            .padding(.top, 8)

                        versionLabel
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Profile")
                        .font(AppFonts.headline(size: 18))
                        .foregroundColor(AppColors.textPrimary)
                }
            }
            .confirmationDialog(
                "Sign out of Layman?",
                isPresented: $showLogoutConfirm,
                titleVisibility: .visible
            ) {
                Button("Sign Out", role: .destructive) {
                    Task { await authViewModel.signOut() }
                }
                Button("Cancel", role: .cancel) {}
            }
            // Privacy Policy sheet
            .sheet(isPresented: $showPrivacyPolicy) {
                SafariView(url: URL(string: "https://www.termsfeed.com/live/privacy-policy")!)
                    .ignoresSafeArea()
            }
            // Notifications not authorised alert
            .alert("Enable Notifications", isPresented: $showNotificationsAlert) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Go to Settings to enable push notifications for breaking news.")
            }
            // Language sheet
            .sheet(isPresented: $showLanguageSheet) {
                LanguageSheet()
            }
            // Mail error
            .alert("Can't Open Mail", isPresented: $showMailError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Send your questions to support@layman.app")
            }
        }
        .onAppear {
            readingStreak = StreakManager.shared.currentStreak
        }
    }

    // MARK: - Avatar Section

    private var avatarSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppColors.accentOrange.opacity(0.15))
                    .frame(width: 88, height: 88)

                Text(authViewModel.currentUser?.initials ?? "?")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(AppColors.accentOrange)
            }

            Text(authViewModel.currentUser?.firstName ?? "User")
                .font(AppFonts.headline(size: 22))
                .foregroundColor(AppColors.textPrimary)

            Text(authViewModel.currentUser?.email ?? "")
                .font(AppFonts.body(size: 14))
                .foregroundColor(AppColors.textSecondary)
        }
    }

    // MARK: - Stats

    private var statsSection: some View {
        HStack(spacing: 0) {
            statItem(value: "\(savedVM.savedArticles.count)", label: "Saved")
            Divider().frame(height: 36)
            streakStat
            Divider().frame(height: 36)
            statItem(value: "∞", label: "Explored")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(AppFonts.headline(size: 22))
                .foregroundColor(AppColors.accentOrange)
            Text(label)
                .font(AppFonts.caption(size: 13))
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var streakStat: some View {
        VStack(spacing: 4) {
            HStack(spacing: 3) {
                Text("\(readingStreak)")
                    .font(AppFonts.headline(size: 22))
                    .foregroundColor(AppColors.accentOrange)
                Text("🔥")
                    .font(.system(size: 18))
            }
            Text("Day Streak")
                .font(AppFonts.caption(size: 13))
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Settings Rows

    private var settingsSection: some View {
        VStack(spacing: 0) {
            // Notifications — opens iOS Settings for this app
            ProfileRow(
                icon: "bell",
                label: "Notifications",
                action: { requestNotificationPermission() }
            )
            Divider().padding(.leading, 52)

            // Language — shows current locale and option to change in Settings
            ProfileRow(
                icon: "globe",
                label: "Language",
                value: Locale.current.localizedString(forLanguageCode: Locale.current.language.languageCode?.identifier ?? "en") ?? "English",
                action: { showLanguageSheet = true }
            )
            Divider().padding(.leading, 52)

            // Rate the App — opens App Store review sheet
            ProfileRow(
                icon: "star",
                label: "Rate Layman",
                action: { requestReview() }
            )
            Divider().padding(.leading, 52)

            // Privacy Policy — opens in Safari
            ProfileRow(
                icon: "lock.shield",
                label: "Privacy Policy",
                action: { showPrivacyPolicy = true }
            )
            Divider().padding(.leading, 52)

            // Help & Support — opens mailto
            ProfileRow(
                icon: "questionmark.circle",
                label: "Help & Support",
                action: { openSupportEmail() }
            )
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Logout

    private var logoutButton: some View {
        Button {
            showLogoutConfirm = true
        } label: {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 16))
                Text("Sign Out")
                    .font(AppFonts.button(size: 16))
            }
            .foregroundColor(.red)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.red.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    private var versionLabel: some View {
        Text("Layman v1.0.0")
            .font(AppFonts.caption(size: 12))
            .foregroundColor(AppColors.textTertiary)
    }

    // MARK: - Actions

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .notDetermined:
                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
                case .denied:
                    showNotificationsAlert = true
                case .authorized, .provisional, .ephemeral:
                    // Already enabled — open settings so user can manage
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                @unknown default:
                    break
                }
            }
        }
    }

    private func requestReview() {
        if let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene }).first {
            SKStoreReviewController.requestReview(in: scene)
        }
    }

    private func openSupportEmail() {
        let email = "support@layman.app"
        let subject = "Layman App Support"
        let body = "\n\n---\nApp Version: 1.0.0\nDevice: \(UIDevice.current.model)\niOS: \(UIDevice.current.systemVersion)"
        let urlString = "mailto:\(email)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"

        if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            showMailError = true
        }
    }
}

// MARK: - Language Sheet

struct LanguageSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.backgroundCream.ignoresSafeArea()

                VStack(spacing: 24) {
                    Spacer()

                    Image(systemName: "globe")
                        .font(.system(size: 56))
                        .foregroundColor(AppColors.accentOrange)

                    VStack(spacing: 8) {
                        Text("Language Settings")
                            .font(AppFonts.headline(size: 22))
                            .foregroundColor(AppColors.textPrimary)

                        Text("Layman is currently available in English. More languages coming soon!")
                            .font(AppFonts.body(size: 15))
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }

                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Text("Change in iOS Settings")
                            .font(AppFonts.button(size: 16))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(AppColors.accentOrange)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal, 24)

                    Spacer()
                }
            }
            .navigationTitle("Language")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(AppColors.accentOrange)
                }
            }
        }
    }
}

// MARK: - ProfileRow

struct ProfileRow: View {
    let icon: String
    let label: String
    var value: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.accentOrange)
                    .frame(width: 28)

                Text(label)
                    .font(AppFonts.body(size: 15))
                    .foregroundColor(AppColors.textPrimary)

                Spacer()

                if let value {
                    Text(value)
                        .font(AppFonts.caption(size: 14))
                        .foregroundColor(AppColors.textTertiary)
                        .lineLimit(1)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppColors.textTertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthViewModel())
        .environmentObject(SavedArticlesViewModel())
}
