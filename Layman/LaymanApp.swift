//
//  LaymanApp.swift
//  Layman
//
//  Created by Nishtha Tandon on 02/04/26.
//

import SwiftUI

@main
struct LaymanApp: App {

    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var savedArticlesViewModel = SavedArticlesViewModel()

    init() {
        // Update daily reading streak on every launch
        _ = StreakManager.shared
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authViewModel)
                .environmentObject(savedArticlesViewModel)
                .preferredColorScheme(.light)
        }
    }
}
