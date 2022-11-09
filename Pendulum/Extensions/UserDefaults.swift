//
//  UserDefaults.swift
//  Pendulum
//
//  Created by Ben Cardy on 04/11/2022.
//

import Foundation

extension UserDefaults {
    
    enum Key: String {
        case sendRemindersToPostLetters
        case sendRemindersToWriteLetters
    }
    
    static let shared = UserDefaults(suiteName: APP_GROUP)!
    
    @objc
    var sendRemindersToPostLetters: Bool {
        get { bool(forKey: Key.sendRemindersToPostLetters.rawValue) }
        set { setValue(newValue, forKey: Key.sendRemindersToPostLetters.rawValue) }
    }
    
    @objc
    var sendRemindersToWriteLetters: Bool {
        get { bool(forKey: Key.sendRemindersToWriteLetters.rawValue) }
        set { setValue(newValue, forKey: Key.sendRemindersToWriteLetters.rawValue) }
    }
    
}
