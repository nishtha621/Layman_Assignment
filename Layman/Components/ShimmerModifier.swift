import SwiftUI

// MARK: - ShimmerModifier

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .white.opacity(0.45), location: 0.5),
                            .init(color: .clear, location: 1)
                        ],
                        startPoint: .init(x: phase, y: 0.5),
                        endPoint: .init(x: phase + 0.5, y: 0.5)
                    )
                    .blendMode(.screen)
                }
            )
            .onAppear {
                withAnimation(
                    .linear(duration: 1.4).repeatForever(autoreverses: false)
                ) {
                    phase = 1.5
                }
            }
    }
}

extension View {
    /// Applies an animated shimmer overlay, used on skeleton loading views.
    func shimmering() -> some View {
        modifier(ShimmerModifier())
    }
}
