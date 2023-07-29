//
//  UserDefaults.swift
//  Pendulum
//
//  Created by Ben Cardy on 04/11/2022.
//

import Foundation

extension UserDefaults {
    
    enum Key: String {
        case lastLaunchedVersion
        case sendRemindersToPostLetters
        case sendRemindersToWriteLetters
        case badgeRemindersToPostLetters
        case badgeRemindersToWriteLetters
        case enableQuickEntry
        case sendRemindersToPostLettersAtHour
        case sendRemindersToPostLettersAtMinute
        case penpalContactMap
        case stopAskingAboutContacts
        case trackPostingLetters
        case sortPenPalsAlphabetically
        case sortStationeryAlphabetically
        case refreshId
    }
    
    static let shared = UserDefaults(suiteName: APP_GROUP)!
    
    @objc
    var trackPostingLetters: Bool {
        get { bool(forKey: Key.trackPostingLetters.rawValue) }
        set { setValue(newValue, forKey: Key.trackPostingLetters.rawValue) }
    }
    
    @objc
    var sortPenPalsAlphabetically: Bool {
        get { bool(forKey: Key.sortPenPalsAlphabetically.rawValue) }
        set { setValue(newValue, forKey: Key.sortPenPalsAlphabetically.rawValue) }
    }
    
    @objc
    var sortStationeryAlphabetically: Bool {
        get { bool(forKey: Key.sortStationeryAlphabetically.rawValue) }
        set { setValue(newValue, forKey: Key.sortStationeryAlphabetically.rawValue) }
    }
    
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
    
    @objc
    var stopAskingAboutContacts: Bool {
        get { bool(forKey: Key.stopAskingAboutContacts.rawValue) }
        set { setValue(newValue, forKey: Key.stopAskingAboutContacts.rawValue) }
    }
    
    func refreshId() {
        setValue(UUID().uuidString, forKey: Key.refreshId.rawValue)
    }
    
    var penpalContactMap: [String: String] {
        get {
            do {
                return try JSONDecoder().decode([String: String].self, from: data(forKey: Key.penpalContactMap.rawValue) ?? Data())
            } catch {
                return [:]
            }
        }
        set {
            do {
                setValue(try JSONEncoder().encode(newValue), forKey: Key.penpalContactMap.rawValue)
            } catch {
                appLogger.debug("Could not save penpalContactMap")
            }
        }
    }
    
    func setContactID(for penpal: PenPal, to identifier: String) {
        if let uuid = penpal.id {
            var currentMap = self.penpalContactMap
            currentMap[uuid.uuidString] = identifier
            self.penpalContactMap = currentMap
        }
    }
    
    func getContactID(for penpal: PenPal) -> String? {
        if let uuid = penpal.id {
            return self.penpalContactMap[uuid.uuidString]
        }
        return nil
    }
    
}
