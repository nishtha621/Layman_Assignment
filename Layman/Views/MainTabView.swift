import SwiftUI

// MARK: - MainTabView

struct MainTabView: View {

    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var savedVM: SavedArticlesViewModel
    @State private var selectedTab: Tab = .home

    enum Tab: Int, CaseIterable {
        case home, saved, profile

        var title: String {
            switch self {
            case .home:    return "Home"
            case .saved:   return "Saved"
            case .profile: return "Profile"
            }
        }

        var icon: String {
            switch self {
            case .home:    return "house"
            case .saved:   return "bookmark"
            case .profile: return "person"
            }
        }

        var selectedIcon: String {
            switch self {
            case .home:    return "house.fill"
            case .saved:   return "bookmark.fill"
            case .profile: return "person.fill"
            }
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Tab content — ZStack isolates each tab (no swipe-between-tabs)
            ZStack {
                HomeView()
                    .opacity(selectedTab == .home ? 1 : 0)
                    .allowsHitTesting(selectedTab == .home)

                SavedView()
                    .opacity(selectedTab == .saved ? 1 : 0)
                    .allowsHitTesting(selectedTab == .saved)

                ProfileView()
                    .opacity(selectedTab == .profile ? 1 : 0)
                    .allowsHitTesting(selectedTab == .profile)
            }
            .animation(.easeInOut(duration: 0.18), value: selectedTab)

            // Custom Tab Bar
            customTabBar
        }
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - Custom Tab Bar

    private var customTabBar: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.rawValue) { tab in
                tabBarButton(tab: tab)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 28)  // safe area bottom
        .background(
            AppColors.tabBarBackground
                .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: -4)
        )
    }

    private func tabBarButton(tab: Tab) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: selectedTab == tab ? tab.selectedIcon : tab.icon)
                    .font(.system(size: 22))
                    .foregroundColor(selectedTab == tab ? AppColors.tabBarSelected : AppColors.tabBarUnselected)
                    .scaleEffect(selectedTab == tab ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedTab)

                Text(tab.title)
                    .font(AppFonts.caption(size: 11))
                    .fontWeight(selectedTab == tab ? .semibold : .regular)
                    .foregroundColor(selectedTab == tab ? AppColors.tabBarSelected : AppColors.tabBarUnselected)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthViewModel())
        .environmentObject(SavedArticlesViewModel())
}
