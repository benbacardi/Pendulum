//
//  PendulumApp.swift
//  Pendulum
//
//  Created by Ben Cardy on 03/11/2022.
//

import SwiftUI

@main
struct PendulumApp: App {
    
    // MARK: Environment
    @Environment(\.scenePhase) var scenePhase
    
    init() {
            // This fixes a bug / feature introduced in iOS 15
            // where the TabBar in SwiftUI is transparent by default.
            let appearance = UITabBarAppearance()
            appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
            // Scrolling behind
            UITabBar.appearance().standardAppearance = appearance
            // When scrolled all the way up
            UITabBar.appearance().scrollEdgeAppearance = appearance
        
            UserDefaults.shared.register(defaults: [
                UserDefaults.Key.sendRemindersToPostLettersAtHour.rawValue: 8,
                UserDefaults.Key.sendRemindersToPostLettersAtMinute.rawValue: 0,
            ])
        
        }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(OrientationObserver.shared)
                .onChange(of: scenePhase) { scenePhase in
                    if scenePhase == .background {
                        Task {
                            await PenPal.scheduleShouldPostLettersNotification()
                            await UIApplication.shared.updateBadgeNumber()
                        }
                    }
                }
        }
    }
}
