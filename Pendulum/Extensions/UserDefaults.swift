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
        case groupPenPalsInListView
        
        case hasPerformedCoreDataMigrationToAppGroup
        case shouldShowDebugView
        
        case exportURL
        case hasGeneratedInitialBackup
        
        case lastSyncDate
    }
    
    static let shared = UserDefaults(suiteName: APP_GROUP)!
    
    var exportURL: URL? {
        get {
            guard let fileName = string(forKey: Key.exportURL.rawValue) else { return nil }
            guard let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
            let fileURL = directory.appendingPathComponent(fileName)
            guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
            return fileURL
        }
        set { setValue(newValue?.lastPathComponent, forKey: Key.exportURL.rawValue) }
    }
    
//    var lastSyncDate: Date? {
//        get {
//            let timeInterval = double(forKey: Key.lastSyncDate.rawValue)
//            guard timeInterval > 0 else { return nil }
//            return Date(timeIntervalSince1970: timeInterval)
//        }
//        set { setValue(newValue?.timeIntervalSince1970 ?? 0, forKey: Key.lastSyncDate.rawValue) }
//    }
    
    var hasGeneratedInitialBackup: Bool {
        get { bool(forKey: Key.hasGeneratedInitialBackup.rawValue) }
        set { setValue(newValue, forKey: Key.hasGeneratedInitialBackup.rawValue) }
    }
    
    var shouldShowDebugView: Bool {
        get { bool(forKey: Key.shouldShowDebugView.rawValue) }
        set { setValue(newValue, forKey: Key.shouldShowDebugView.rawValue) }
    }
    
    var groupPenPalsInListView: Bool {
        get { bool(forKey: Key.groupPenPalsInListView.rawValue) }
        set { setValue(newValue, forKey: Key.groupPenPalsInListView.rawValue) }
    }
    
    var hasPerformedCoreDataMigrationToAppGroup: Bool {
        get { bool(forKey: Key.hasPerformedCoreDataMigrationToAppGroup.rawValue) }
        set { setValue(newValue, forKey: Key.hasPerformedCoreDataMigrationToAppGroup.rawValue) }
    }
    
    var trackPostingLetters: Bool {
        get { bool(forKey: Key.trackPostingLetters.rawValue) }
        set { setValue(newValue, forKey: Key.trackPostingLetters.rawValue) }
    }
    
    var sortPenPalsAlphabetically: Bool {
        get { bool(forKey: Key.sortPenPalsAlphabetically.rawValue) }
        set { setValue(newValue, forKey: Key.sortPenPalsAlphabetically.rawValue) }
    }
    
    var sortStationeryAlphabetically: Bool {
        get { bool(forKey: Key.sortStationeryAlphabetically.rawValue) }
        set { setValue(newValue, forKey: Key.sortStationeryAlphabetically.rawValue) }
    }
    
    var sendRemindersToPostLetters: Bool {
        get { bool(forKey: Key.sendRemindersToPostLetters.rawValue) }
        set { setValue(newValue, forKey: Key.sendRemindersToPostLetters.rawValue) }
    }
    
    var sendRemindersToWriteLetters: Bool {
        get { bool(forKey: Key.sendRemindersToWriteLetters.rawValue) }
        set { setValue(newValue, forKey: Key.sendRemindersToWriteLetters.rawValue) }
    }
    
    var badgeRemindersToPostLetters: Bool {
        get { bool(forKey: Key.badgeRemindersToPostLetters.rawValue) }
        set { setValue(newValue, forKey: Key.badgeRemindersToPostLetters.rawValue) }
    }
    
    var badgeRemindersToWriteLetters: Bool {
        get { bool(forKey: Key.badgeRemindersToWriteLetters.rawValue) }
        set { setValue(newValue, forKey: Key.badgeRemindersToWriteLetters.rawValue) }
    }
    
    var enableQuickEntry: Bool {
        get { bool(forKey: Key.enableQuickEntry.rawValue) }
        set { setValue(newValue, forKey: Key.enableQuickEntry.rawValue) }
    }
    
    var sendRemindersToPostLettersAtHour: Int {
        get { integer(forKey: Key.sendRemindersToPostLettersAtHour.rawValue) }
        set { setValue(newValue, forKey: Key.sendRemindersToPostLettersAtHour.rawValue) }
    }
    
    var sendRemindersToPostLettersAtMinute: Int {
        get { integer(forKey: Key.sendRemindersToPostLettersAtMinute.rawValue) }
        set { setValue(newValue, forKey: Key.sendRemindersToPostLettersAtMinute.rawValue) }
    }
    
    var stopAskingAboutContacts: Bool {
        get { bool(forKey: Key.stopAskingAboutContacts.rawValue) }
        set { setValue(newValue, forKey: Key.stopAskingAboutContacts.rawValue) }
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
