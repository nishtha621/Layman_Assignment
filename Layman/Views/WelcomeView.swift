import SwiftUI
import Combine

// MARK: - WelcomeView

struct WelcomeView: View {

    @EnvironmentObject private var authViewModel: AuthViewModel

    @State private var logoOpacity: Double = 0
    @State private var logoOffset: CGFloat = -20
    @State private var sloganOpacity: Double = 0
    @State private var sloganOffset: CGFloat = 24
    @State private var sliderOpacity: Double = 0
    @State private var navigateToAuth: Bool = false

    // Swipe state
    @State private var sliderOffset: CGFloat = 0
    @State private var hasCompleted: Bool = false

    private let sliderHeight: CGFloat = 60
    // thumb occupies left portion of the pill
    private let thumbWidth: CGFloat = 52
    private let trackHPad: CGFloat  = 28
    private var trackWidth: CGFloat { UIScreen.main.bounds.width - trackHPad * 2 }
    private var maxOffset: CGFloat  { trackWidth - thumbWidth - 4 }
    private var progress: CGFloat   { maxOffset > 0 ? sliderOffset / maxOffset : 0 }

    var body: some View {
        NavigationStack {
            ZStack {
                // Warm peach gradient — matches prototype (top/bottom peach, bright centre)
                LinearGradient(
                    stops: [
                        .init(color: Color(hex: "#E8A87C"), location: 0.0),
                        .init(color: Color(.white), location: 0.5),
                        .init(color: Color(hex: "#F0C4A0"), location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    
                    Text("Layman")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundColor(Color(hex: "#1A1A1A"))
                        .tracking(-0.5)
                        .opacity(logoOpacity)
                        .offset(y: logoOffset)
                        .padding(.top, 60)

                    Spacer()

                    VStack(alignment: .center, spacing: 2) {
                        Text("Business,\ntech & startups")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(Color(hex: "#1A1A1A"))
                            .lineSpacing(4)
                            .multilineTextAlignment(.center)
                        Text("made simple")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(AppColors.accentOrange)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, 24)
                    .opacity(sloganOpacity)
                    .offset(y: sloganOffset)

                    Spacer()
                    Spacer()

                    // Swipe Slider
                    swipeSlider
                        .opacity(sliderOpacity)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 52)
                }
            }
            .navigationDestination(isPresented: $navigateToAuth) {
                AuthView()
            }
        }
        .onAppear(perform: runEntryAnimations)
        .onChange(of: hasCompleted) { _, completed in
            if completed { navigateToAuth = true }
        }
    }

    // MARK: - Swipe Slider

    /// Prototype style: full orange pill track, ">>" thumb on the left,
    /// "Swipe to get started…" text fades as thumb moves right.
    private var swipeSlider: some View {
        ZStack(alignment: .leading) {
            // Orange pill background — always full width
            Capsule()
                .fill(AppColors.accentOrange)
                .frame(height: sliderHeight)

            // Lightened "progress" overlay fades in from left as user drags
            Capsule()
                .fill(Color.white.opacity(0.15 * progress))
                .frame(height: sliderHeight)

            // Label — "Swipe to get started…"  fades out as progress →1
            Text("Swipe to get started...")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white.opacity(max(0, 1.0 - progress * 2.5)))
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
                .padding(.leading, thumbWidth + 8)
                .padding(.trailing, 16)
                .allowsHitTesting(false)

            // Thumb — white circle with ">>" chevrons
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: thumbWidth, height: thumbWidth)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

                Image(systemName: hasCompleted ? "checkmark" : "chevron.right.2")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppColors.accentOrange)
                    .scaleEffect(hasCompleted ? 1.15 : 1.0)
                    .animation(.spring(response: 0.25), value: hasCompleted)
            }
            .padding(4)
            .offset(x: sliderOffset)
            .gesture(
                DragGesture(minimumDistance: 4)
                    .onChanged { value in
                        guard !hasCompleted else { return }
                        sliderOffset = min(max(0, value.translation.width), maxOffset)
                    }
                    .onEnded { _ in
                        guard !hasCompleted else { return }
                        if progress > 0.78 {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                sliderOffset = maxOffset
                            }
                            hasCompleted = true
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                navigateToAuth = true
                            }
                        } else {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                sliderOffset = 0
                            }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    }
            )
        }
        .frame(height: sliderHeight)
        .clipShape(Capsule())
    }

    // MARK: - Entry Animations

    private func runEntryAnimations() {
        withAnimation(.spring(response: 0.65, dampingFraction: 0.78).delay(0.1)) {
            logoOpacity   = 1
            logoOffset    = 0
        }
        withAnimation(.spring(response: 0.65, dampingFraction: 0.78).delay(0.3)) {
            sloganOpacity = 1
            sloganOffset  = 0
        }
        withAnimation(.easeOut(duration: 0.45).delay(0.6)) {
            sliderOpacity = 1
        }
    }
}

#Preview {
    WelcomeView()
        .environmentObject(AuthViewModel())
}
