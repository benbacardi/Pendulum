//
//  UIApplication.swift
//  Pendulum
//
//  Created by Ben Cardy on 04/11/2022.
//

import Foundation
import UIKit

extension UIApplication {
    
    static var systemSettingsURL: URL? {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return nil }
        guard UIApplication.shared.canOpenURL(url) else { return nil }
        return url
    }
    
    func updateBadgeNumber() {
        let fetchedBadgeNumber = PenPal.calculateBadgeNumber(toWrite: UserDefaults.shared.badgeRemindersToWriteLetters, toPost: UserDefaults.shared.badgeRemindersToPostLetters)
        appLogger.debug("Setting applicationIconBadgeNumber to \(fetchedBadgeNumber)")
        DispatchQueue.main.async {
            self.applicationIconBadgeNumber = fetchedBadgeNumber
        }
    }
    
}
