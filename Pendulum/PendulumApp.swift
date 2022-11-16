//
//  PendulumApp.swift
//  Pendulum
//
//  Created by Ben Cardy on 03/11/2022.
//

import SwiftUI
import CloudKit
import NotificationCenter

@main
struct PendulumApp: App {
    
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    
    // MARK: Environment
    @Environment(\.scenePhase) var scenePhase
    
    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
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
                    /// Set badges and notificaitons when we background
                    if scenePhase == .background {
                        Task {
                            await PenPal.scheduleShouldPostLettersNotification()
                            await UIApplication.shared.updateBadgeNumber()
                        }
                        Task {
                            await CloudKitController.shared.performFullSync()
                        }
                    }
                    /// Run sync when we start
                    if scenePhase == .active {
                        Task {
                            await CloudKitController.shared.performFullSync()
                        }
                    }
                }
                .task {
                    await CloudKitController.shared.subscribeToChanges()
                }
                .onReceive(timer) { input in
                    Task {
                        await CloudKitController.shared.performFullSync()
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: SyncRequiredNotification, object: nil)) { notification in
                    appLogger.debug("Received syncRequested notification")
                    Task {
                        await CloudKitController.shared.performFullSync()
                    }
                }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UIApplication.shared.registerForRemoteNotifications()
        return true
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        appLogger.debug("Remote notification received")
        if let notification = CKNotification(fromRemoteNotificationDictionary: userInfo) {
            cloudKitLogger.debug("CloudKit notification: \(notification)")
            DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 3) {
                Task {
                    await CloudKitController.shared.performFullSync()
                }
            }
            completionHandler(.newData)
            return
        }
        completionHandler(.noData)
    }
    
}
