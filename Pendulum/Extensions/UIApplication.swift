//
//  UIApplication.swift
//  Pendulum
//
//  Created by Ben Cardy on 04/11/2022.
//

import Foundation
import UIKit
import UserNotifications

extension UIApplication {
    
    static var systemSettingsURL: URL? {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return nil }
        guard UIApplication.shared.canOpenURL(url) else { return nil }
        return url
    }
    
    func updateBadgeNumber() {
        let fetchedBadgeNumber = PenPal.calculateBadgeNumber(toWrite: UserDefaults.shared.badgeRemindersToWriteLetters, toPost: UserDefaults.shared.badgeRemindersToPostLetters && UserDefaults.shared.trackPostingLetters)
        appLogger.debug("Setting the app icon badge to \(fetchedBadgeNumber)")
        /// setBadgeCount replaces applicationIconBadgeNumber, deprecated in iOS 17. It is the API
        /// that respects the user's badge permission, so it reports a refusal rather than silently
        /// doing nothing — and it needs no hop to the main queue of its own
        Task {
            do {
                try await UNUserNotificationCenter.current().setBadgeCount(fetchedBadgeNumber)
            } catch {
                appLogger.error("Could not set the app icon badge: \(error.localizedDescription)")
            }
        }
    }
    
}
