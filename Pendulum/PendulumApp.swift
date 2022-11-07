//
//  PendulumApp.swift
//  Pendulum
//
//  Created by Ben Cardy on 03/11/2022.
//

import SwiftUI

@main
struct PendulumApp: App {
    init() {
            // This fixes a bug / feature introduced in iOS 15
            // where the TabBar in SwiftUI is transparent by default.
            let appearance = UITabBarAppearance()
            appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
            // Scrolling behind
            UITabBar.appearance().standardAppearance = appearance
            // When scrolled all the way up
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
