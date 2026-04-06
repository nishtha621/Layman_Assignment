import SwiftUI
import Combine

// MARK: - ChatView

struct ChatView: View {

    let article: Article
    @StateObject private var vm: ChatViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isInputFocused: Bool

    init(article: Article) {
        self.article = article
        _vm = StateObject(wrappedValue: ChatViewModel(article: article))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColors.backgroundCream.ignoresSafeArea()

            VStack(spacing: 0) {
                chatHeader
                messageList
                inputArea
            }
        }
        .navigationBarHidden(true)
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }

    // MARK: - Header
    // Shows blurred article headline at top — like the prototype

    private var chatHeader: some View {
        ZStack {
            // Article image as blurred background (if available)
            AsyncImageView(urlString: article.imageURL)
                .frame(maxWidth: .infinity)
                .frame(height: 80)
                .blur(radius: 14)
                .overlay(Color.black.opacity(0.35))
                .clipped()

            // Title overlay
            HStack(spacing: 0) {
                // Close button
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Circle())
                }

                Spacer()

                // Article headline — truncated
                Text(article.headline)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 12)

                Spacer()
                // Spacer to balance the X button
                Color.clear.frame(width: 32, height: 32)
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 80)
    }

    // MARK: - Message List

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 14) {
                    // Messages
                    ForEach(vm.messages) { message in
                        ChatBubbleView(message: message)
                            .id(message.id)
                    }

                    // "Question Suggestions:" + chips — shown below first welcome message
                    if !vm.suggestedQuestions.isEmpty && !vm.isLoading {
                        suggestedQuestionsView
                            .padding(.top, 4)
                            .transition(.opacity.animation(.easeIn(duration: 0.3)))
                    }

                    // Typing indicator spacer
                    Color.clear.frame(height: 1).id("bottom")
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 110)
            }
            .onChange(of: vm.messages.count) { _, _ in
                withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
            }
            .onChange(of: isInputFocused) { _, _ in
                withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
            }
        }
    }

    // MARK: - Suggested Questions
    // Prototype: "Question Suggestions:" label + solid ORANGE pills with white text

    private var suggestedQuestionsView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Question Suggestions:")
                .font(AppFonts.caption(size: 13))
                .foregroundColor(AppColors.textSecondary)

            ForEach(vm.suggestedQuestions, id: \.self) { question in
                Button {
                    Task { await vm.sendSuggestedQuestion(question) }
                } label: {
                    Text(question)
                        .font(AppFonts.body(size: 15))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppColors.accentOrange)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Input Area

    private var inputArea: some View {
        VStack(spacing: 0) {
            Divider().overlay(Color(hex: "#E8DDD5"))

            HStack(spacing: 10) {
                // Text field pill
                HStack(spacing: 8) {
                    TextField("Type your question...", text: $vm.inputText, axis: .vertical)
                        .font(AppFonts.body(size: 15))
                        .foregroundColor(AppColors.textPrimary)
                        .focused($isInputFocused)
                        .lineLimit(1...3)
                        .submitLabel(.send)
                        .onSubmit {
                            Task { await vm.sendMessage() }
                        }

                    // Mic icon
                    Image(systemName: "mic")
                        .font(.system(size: 17))
                        .foregroundColor(AppColors.textTertiary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(hex: "#F0E8E0"))
                .clipShape(Capsule())

                // Send button — orange circle
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    Task { await vm.sendMessage() }
                } label: {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 42, height: 42)
                        .background(
                            vm.inputText.trimmingCharacters(in: .whitespaces).isEmpty
                                ? Color(hex: "#C9B8AE")
                                : AppColors.accentOrange
                        )
                        .clipShape(Circle())
                }
                .disabled(vm.inputText.trimmingCharacters(in: .whitespaces).isEmpty || vm.isLoading)
                .animation(.easeInOut(duration: 0.18), value: vm.inputText.isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .padding(.bottom, 20)
            .background(Color.white)
        }
    }
}

// MARK: - ChatBubbleView
// Prototype: bot = left-aligned cream bubble with orange "L" avatar
//            user = right-aligned, orange avatar on far right

struct ChatBubbleView: View {

    let message: ChatMessage
    var isBot: Bool { message.role == .bot }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {

            if isBot {
                // Orange "L" avatar
                laymanAvatar
            } else {
                Spacer(minLength: 44)
            }

            // Bubble
            Group {
                if message.isAnimating {
                    TypingIndicatorView()
                        .padding(.horizontal, 16)
                        .padding(.vertical, 13)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(hex: "#F0E8E0"))
                        )
                } else {
                    Text(message.text)
                        .font(AppFonts.body(size: 15))
                        .foregroundColor(isBot ? AppColors.textPrimary : .white)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(isBot ? Color(hex: "#F0E8E0") : AppColors.accentOrange)
                        )
                }
            }
            .frame(maxWidth: UIScreen.main.bounds.width * 0.72, alignment: isBot ? .leading : .trailing)

            if !isBot {
                // Person icon for user
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(Color(hex: "#C9B8AE"))
            }
        }
        .frame(maxWidth: .infinity, alignment: isBot ? .leading : .trailing)
        .transition(.asymmetric(
            insertion: .move(edge: isBot ? .leading : .trailing).combined(with: .opacity),
            removal: .opacity
        ))
    }

    private var laymanAvatar: some View {
        ZStack {
            Circle()
                .fill(AppColors.accentOrange)
                .frame(width: 30, height: 30)
            Text("L")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

// MARK: - TypingIndicatorView

struct TypingIndicatorView: View {
    @State private var phase: Int = 0
    private let timer = Timer.publish(every: 0.35, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(AppColors.textTertiary)
                    .frame(width: 7, height: 7)
                    .scaleEffect(phase == i ? 1.3 : 0.9)
                    .animation(
                        .spring(response: 0.3, dampingFraction: 0.5).delay(Double(i) * 0.08),
                        value: phase
                    )
            }
        }
        .onReceive(timer) { _ in phase = (phase + 1) % 3 }
    }
}

#Preview {
    ChatView(article: .preview)
}
