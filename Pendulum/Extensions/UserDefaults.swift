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
        case badgeRemindersToPostLetters
        case badgeRemindersToWriteLetters
        case enableQuickEntry
        case sendRemindersToPostLettersAtHour
        case sendRemindersToPostLettersAtMinute
        case entryFields
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
    
    @objc
    var badgeRemindersToPostLetters: Bool {
        get { bool(forKey: Key.badgeRemindersToPostLetters.rawValue) }
        set { setValue(newValue, forKey: Key.badgeRemindersToPostLetters.rawValue) }
    }
    
    @objc
    var badgeRemindersToWriteLetters: Bool {
        get { bool(forKey: Key.badgeRemindersToWriteLetters.rawValue) }
        set { setValue(newValue, forKey: Key.badgeRemindersToWriteLetters.rawValue) }
    }
    
    @objc
    var enableQuickEntry: Bool {
        get { bool(forKey: Key.enableQuickEntry.rawValue) }
        set { setValue(newValue, forKey: Key.enableQuickEntry.rawValue) }
    }
    
    @objc
    var sendRemindersToPostLettersAtHour: Int {
        get { integer(forKey: Key.sendRemindersToPostLettersAtHour.rawValue) }
        set { setValue(newValue, forKey: Key.sendRemindersToPostLettersAtHour.rawValue) }
    }
    
    @objc
    var sendRemindersToPostLettersAtMinute: Int {
        get { integer(forKey: Key.sendRemindersToPostLettersAtMinute.rawValue) }
        set { setValue(newValue, forKey: Key.sendRemindersToPostLettersAtMinute.rawValue) }
    }
    
    var entryFields: Set<String> {
        get { Set(array(forKey: Key.entryFields.rawValue) as? [String] ?? DEFAULT_ENTRY_FIELDS) }
        set { setValue(Array(newValue), forKey: Key.entryFields.rawValue) }
    }
    
}
