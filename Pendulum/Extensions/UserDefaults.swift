//
//  UserDefaults.swift
//  Pendulum
//
//  Created by Ben Cardy on 04/11/2022.
//

import Foundation

extension UserDefaults {
    
    enum Key: String {
        case hasRequestedContactsAccess
    }
    
    static let shared = UserDefaults(suiteName: APP_GROUP)!
    
    @objc
    var hasRequestedContactsAccess: Bool {
        get { bool(forKey: Key.hasRequestedContactsAccess.rawValue) }
        set { setValue(newValue, forKey: Key.hasRequestedContactsAccess.rawValue) }
    }
    
}
