//
//  UIApplication.swift
//  Pendulum
//
//  Created by Ben Cardy on 04/11/2022.
//

import Foundation
import UIKit

extension UIApplication {
    
    func updateBadgeNumber() {
        let fetchedBadgeNumber = PenPal.calculateBadgeNumber(toWrite: UserDefaults.shared.badgeRemindersToWriteLetters, toPost: UserDefaults.shared.badgeRemindersToPostLetters && UserDefaults.shared.trackPostingLetters)
        appLogger.debug("Setting applicationIconBadgeNumber to \(fetchedBadgeNumber)")
        DispatchQueue.main.async {
            self.applicationIconBadgeNumber = fetchedBadgeNumber
//            WidgetType.NonInteractiveWidget.reload()
        }
    }
    
}
