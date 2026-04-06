//
//  RootView.swift
//  Layman
//
//  Created by Nishtha Tandon on 03/04/26.
//


import SwiftUI
 
/// Controls the root navigation flow:
/// Welcome → Auth → Main App (tab bar)
struct RootView: View {
 
    @EnvironmentObject private var authViewModel: AuthViewModel
 
    var body: some View {
        Group {
            switch authViewModel.authState {
            case .unauthenticated:
                WelcomeView()
            case .authenticated:
                MainTabView()
            case .loading:
                SplashView()
            }
        }
        .animation(.easeInOut(duration: 0.4), value: authViewModel.authState)
    }
}
 