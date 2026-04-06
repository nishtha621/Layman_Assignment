import SwiftUI

// MARK: - EmptyStateView

struct EmptyStateView: View {

    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 44))
                .foregroundColor(AppColors.accentOrange.opacity(0.6))

            VStack(spacing: 6) {
                Text(title)
                    .font(AppFonts.subheadline(size: 17))
                    .foregroundColor(AppColors.textPrimary)

                Text(message)
                    .font(AppFonts.body(size: 14))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(AppFonts.button(size: 14))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(AppColors.accentOrange)
                        .clipShape(Capsule())
                }
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    EmptyStateView(
        icon: "bookmark",
        title: "Nothing saved yet",
        message: "Tap the bookmark on any story to save it here",
        actionTitle: "Browse Stories",
        action: {}
    )
    .padding()
}
