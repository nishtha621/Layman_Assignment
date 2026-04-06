//
//  SplashView.swift
//  Layman
//
//  Created by Nishtha Tandon on 03/04/26.
//


import SwiftUI

// MARK: - SplashView
// Shown on cold launch while AuthViewModel checks for an existing Supabase session.
// Transitions automatically to WelcomeView (new user) or MainTabView (returning user).

struct SplashView: View {

    // MARK: - Animation State

    @State private var logoScale: CGFloat = 0.7
    @State private var logoOpacity: Double = 0
    @State private var taglineOpacity: Double = 0
    @State private var taglineOffset: CGFloat = 12
    @State private var spinnerOpacity: Double = 0

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background gradient — same peach-to-orange as WelcomeView
            AppColors.welcomeGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo
                Text("Layman")
                    .font(AppFonts.logo(size: 48))
                    .foregroundColor(Color(hex: "#2C1810"))
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)

                // Tagline
                HStack(spacing: 4) {
                    Text("Business,\n tech & startups")
                        .foregroundColor(Color(hex: "#2C1810").opacity(0.75))
                    +
                    Text(" made simple")
                        .foregroundColor(AppColors.accentOrange)
                }
                .font(.system(size: 14, weight: .medium))
                .opacity(taglineOpacity)
                .offset(y: taglineOffset)
                .padding(.top, 10)

                Spacer()

                // Loading spinner — appears after logo settles
                ProgressView()
                    .tint(AppColors.accentOrange)
                    .scaleEffect(1.1)
                    .opacity(spinnerOpacity)
                    .padding(.bottom, 60)
            }
        }
        .onAppear { runAnimations() }
    }

    // MARK: - Animations

    private func runAnimations() {
        // 1. Logo pops in
        withAnimation(.spring(response: 0.55, dampingFraction: 0.65)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }

        // 2. Tagline slides up
        withAnimation(.easeOut(duration: 0.45).delay(0.3)) {
            taglineOpacity = 1.0
            taglineOffset = 0
        }

        // 3. Spinner fades in
        withAnimation(.easeIn(duration: 0.3).delay(0.55)) {
            spinnerOpacity = 1.0
        }
    }
}

// MARK: - Preview

#Preview {
    SplashView()
}
