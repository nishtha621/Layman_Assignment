import SwiftUI
import SafariServices

// MARK: - ArticleDetailView

struct ArticleDetailView: View {

    let article: Article
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var savedVM: SavedArticlesViewModel
    @StateObject private var vm: ArticleDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showChat: Bool = false

    init(article: Article) {
        self.article = article
        _vm = StateObject(wrappedValue: ArticleDetailViewModel(article: article))
    }

    var body: some View {
        ZStack(alignment: .top) {
            AppColors.backgroundCream.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Top bar space (overlaid absolutely)
                    Color.clear
                        .frame(height: safeAreaTop + 52)

                    // Article Header (Headline first — per spec)
                    articleHeader
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                    // Article Photo — below headline, full width
                    articlePhoto
                        .padding(.top, 16)

                    // Content cards section
                    VStack(alignment: .leading, spacing: 20) {
                        cardSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 20)
                }
            }
            // Fixes button floating safely above TabBar while not blocking ScrollView
            .safeAreaInset(edge: .bottom) {
                askLaymanButton
                    .padding(.bottom, 100) // Tab bar clearance
            }

            // Sticky top bar (overlaid at top)
            topBar
                .padding(.top, safeAreaTop)
        }
        .navigationBarHidden(true)
        .ignoresSafeArea(edges: .top)
        .sheet(isPresented: $vm.showSafariSheet) {
            if let url = vm.originalURL {
                SafariView(url: url)
                    .ignoresSafeArea()
            }
        }
        .sheet(isPresented: $showChat) {
            ChatView(article: article)
        }
        .sheet(isPresented: $vm.showShareSheet) {
            ShareSheet(items: vm.shareItems)
        }
    }

    // MARK: - Safe Area

    private var safeAreaTop: CGFloat {
        (UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets.top) ?? 44
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: 12) {
            // Back
            CircleIconButton(icon: "chevron.left") { dismiss() }

            Spacer()

            // Link
            CircleIconButton(icon: "link") { vm.openOriginalArticle() }

            // Bookmark
            CircleIconButton(
                icon: savedVM.isArticleSaved(article) ? "bookmark.fill" : "bookmark",
                tint: savedVM.isArticleSaved(article) ? AppColors.accentOrange : AppColors.textPrimary
            ) {
                guard let userID = authViewModel.currentUser?.id else { return }
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
                Task {
                    if savedVM.isArticleSaved(article) {
                        await savedVM.unsave(article: article, userID: userID)
                    } else {
                        try? await SupabaseManager.shared.saveArticle(article, userID: userID)
                        await savedVM.fetchSavedArticles(userID: userID)
                    }
                }
            }

            // Share
            CircleIconButton(icon: "square.and.arrow.up") { vm.openShareSheet() }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Article Header (Headline — exactly 2 lines)

    private var articleHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Source + date chip
            HStack(spacing: 6) {
                Text(article.sourceName.uppercased())
                    .font(AppFonts.caption(size: 11))
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.accentOrange)

                Text("·")
                    .foregroundColor(AppColors.textTertiary)

                Text(article.formattedDate)
                    .font(AppFonts.caption(size: 12))
                    .foregroundColor(AppColors.textTertiary)
            }

            // Headline — bold, exactly 2 lines enforced
            Text(article.headline)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Article Photo (below headline, full width)

    private var articlePhoto: some View {
        AsyncImageView(urlString: article.imageURL)
            .frame(maxWidth: .infinity)
            .frame(height: 240)
            .clipped()
    }

    // MARK: - Swipeable Cards Section

    private var cardSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("The Simple Version")
                    .font(AppFonts.subheadline(size: 14))
                    .foregroundColor(AppColors.textSecondary)

                Spacer()

                // Retry button — shown when AI failed and fallback cards are used
                if vm.cardLoadFailed && !vm.isLoadingCards {
                    Button {
                        Task { await vm.retryAICards() }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 11, weight: .semibold))
                            Text("Retry AI")
                                .font(AppFonts.caption(size: 12))
                        }
                        .foregroundColor(AppColors.accentOrange)
                    }
                }
            }

            if vm.isLoadingCards {
                // Skeleton cards while AI generates
                ForEach(0..<3, id: \.self) { _ in
                    ContentCardSkeletonView()
                }
            } else {
                SwipeableCardsView(
                    cards: vm.contentCards,
                    currentIndex: $vm.currentCardIndex
                )
            }
        }
    }

    // MARK: - Ask Layman Button

    private var askLaymanButton: some View {
        Button {
            showChat = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 16, weight: .semibold))
                Text("Ask Layman")
                    .font(AppFonts.button(size: 16))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(AppColors.accentOrange)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: AppColors.accentOrange.opacity(0.4), radius: 12, x: 0, y: 4)
        }
        .padding(.horizontal, 20)
        .background(
            LinearGradient(
                colors: [AppColors.backgroundCream.opacity(0), AppColors.backgroundCream, AppColors.backgroundCream],
                startPoint: .top,
                endPoint: UnitPoint(x: 0.5, y: 0.5)
            )
            .padding(.top, -24)
            .padding(.bottom, -120) // Extend gradient to cover what's underneath
        )
    }
}

// MARK: - SwipeableCardsView

struct SwipeableCardsView: View {

    let cards: [ContentCard]
    @Binding var currentIndex: Int
    @GestureState private var dragOffset: CGFloat = 0

    var body: some View {
        VStack(spacing: 12) {
            // Card stack
            ZStack {
                ForEach(cards.reversed()) { card in
                    ContentCardView(card: card, index: card.id, currentIndex: currentIndex)
                        .offset(x: card.id == currentIndex ? dragOffset : 0)
                        .gesture(
                            DragGesture()
                                .updating($dragOffset) { value, state, _ in
                                    state = value.translation.width
                                }
                                .onEnded { value in
                                    handleSwipe(translation: value.translation.width)
                                }
                        )
                }
            }

            // Step indicator
            HStack(spacing: 6) {
                ForEach(0..<cards.count, id: \.self) { i in
                    Circle()
                        .fill(i == currentIndex ? AppColors.accentOrange : Color(hex: "#D4C4B8"))
                        .frame(width: 7, height: 7)
                        .animation(.spring(response: 0.3), value: currentIndex)
                }
                Spacer()
                Text("\(currentIndex + 1) of \(cards.count)")
                    .font(AppFonts.caption(size: 12))
                    .foregroundColor(AppColors.textTertiary)
            }
        }
    }

    private func handleSwipe(translation: CGFloat) {
        let threshold: CGFloat = 60
        let impact = UIImpactFeedbackGenerator(style: .light)
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            if translation < -threshold, currentIndex < cards.count - 1 {
                currentIndex += 1
                impact.impactOccurred()
            } else if translation > threshold, currentIndex > 0 {
                currentIndex -= 1
                impact.impactOccurred()
            }
        }
    }
}

// MARK: - ContentCardView

struct ContentCardView: View {

    let card: ContentCard
    let index: Int
    let currentIndex: Int

    private var offset: CGFloat {
        let diff = index - currentIndex
        return CGFloat(diff) * 6
    }

    private var scale: CGFloat {
        let diff = abs(index - currentIndex)
        return 1.0 - CGFloat(diff) * 0.04
    }

    var body: some View {
        Text(card.text)
            .font(AppFonts.body(size: 16))
            .foregroundColor(AppColors.textPrimary)
            .lineSpacing(5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 140)          // Exactly 6 lines
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(index == currentIndex ? Color.white : AppColors.cardSurface)
                    .shadow(
                        color: .black.opacity(index == currentIndex ? 0.08 : 0.04),
                        radius: index == currentIndex ? 12 : 6,
                        x: 0, y: index == currentIndex ? 4 : 2
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        index == currentIndex ? AppColors.accentOrange.opacity(0.2) : Color.clear,
                        lineWidth: 1.5
                    )
            )
            .scaleEffect(scale)
            .offset(y: offset)
            .zIndex(index == currentIndex ? 1 : 0)
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: currentIndex)
    }
}

// MARK: - ContentCardSkeletonView

struct ContentCardSkeletonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(0..<4, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: "#EDE0D6"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 13)
            }
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(hex: "#EDE0D6"))
                .frame(width: 160)
                .frame(height: 13)
        }
        .padding(20)
        .frame(height: 140)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shimmering()
    }
}

// MARK: - CircleIconButton

struct CircleIconButton: View {
    let icon: String
    var tint: Color = AppColors.textPrimary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(tint)
                .frame(width: 38, height: 38)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
        }
    }
}

// MARK: - SafariView

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = true
        let vc = SFSafariViewController(url: url, configuration: config)
        vc.preferredControlTintColor = UIColor(AppColors.accentOrange)
        return vc
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

// MARK: - ShareSheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        ArticleDetailView(article: .preview)
            .environmentObject(AuthViewModel())
            .environmentObject(SavedArticlesViewModel())
    }
}
