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
    
}

extension UserDefaults {
    func string(forKey key: UserDefaults.Key) -> String? { string(forKey: key.rawValue) }
    func array(forKey key: UserDefaults.Key) -> [Any]? { array(forKey: key.rawValue) }
    func dictionary(forKey key: UserDefaults.Key) -> [String : Any]? { dictionary(forKey: key.rawValue) }
    func data(forKey key: UserDefaults.Key) -> Data? { data(forKey: key.rawValue) }
    func stringArray(forKey key: UserDefaults.Key) -> [String]? { stringArray(forKey: key.rawValue) }
    func integer(forKey key: UserDefaults.Key) -> Int { integer(forKey: key.rawValue) }
    func float(forKey key: UserDefaults.Key) -> Float { float(forKey: key.rawValue) }
    func double(forKey key: UserDefaults.Key) -> Double { double(forKey: key.rawValue) }
    func bool(forKey key: UserDefaults.Key) -> Bool { bool(forKey: key.rawValue) }
    func url(forKey key: UserDefaults.Key) -> URL? { url(forKey: key.rawValue) }
    func setValue(_ value: Any?, forKey key: UserDefaults.Key) { setValue(value, forKey: key.rawValue) }
}

extension UserDefaults {
    
    var exportURL: URL? {
        get {
            guard let fileName = string(forKey: Key.exportURL) else { return nil }
            guard let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
            let fileURL = directory.appendingPathComponent(fileName)
            guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
            return fileURL
        }
        set { setValue(newValue?.lastPathComponent, forKey: Key.exportURL) }
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
        get { bool(forKey: Key.hasGeneratedInitialBackup) }
        set { setValue(newValue, forKey: Key.hasGeneratedInitialBackup) }
    }
    
    var shouldShowDebugView: Bool {
        get { bool(forKey: Key.shouldShowDebugView) }
        set { setValue(newValue, forKey: Key.shouldShowDebugView) }
    }
    
    var groupPenPalsInListView: Bool {
        get { bool(forKey: Key.groupPenPalsInListView) }
        set { setValue(newValue, forKey: Key.groupPenPalsInListView) }
    }
    
    var hasPerformedCoreDataMigrationToAppGroup: Bool {
        get { bool(forKey: Key.hasPerformedCoreDataMigrationToAppGroup) }
        set { setValue(newValue, forKey: Key.hasPerformedCoreDataMigrationToAppGroup) }
    }
    
    var trackPostingLetters: Bool {
        get { bool(forKey: Key.trackPostingLetters) }
        set { setValue(newValue, forKey: Key.trackPostingLetters) }
    }
    
    var sortPenPalsAlphabetically: Bool {
        get { bool(forKey: Key.sortPenPalsAlphabetically) }
        set { setValue(newValue, forKey: Key.sortPenPalsAlphabetically) }
    }
    
    var sortStationeryAlphabetically: Bool {
        get { bool(forKey: Key.sortStationeryAlphabetically) }
        set { setValue(newValue, forKey: Key.sortStationeryAlphabetically) }
    }
    
    var sendRemindersToPostLetters: Bool {
        get { bool(forKey: Key.sendRemindersToPostLetters) }
        set { setValue(newValue, forKey: Key.sendRemindersToPostLetters) }
    }
    
    var sendRemindersToWriteLetters: Bool {
        get { bool(forKey: Key.sendRemindersToWriteLetters) }
        set { setValue(newValue, forKey: Key.sendRemindersToWriteLetters) }
    }
    
    var badgeRemindersToPostLetters: Bool {
        get { bool(forKey: Key.badgeRemindersToPostLetters) }
        set { setValue(newValue, forKey: Key.badgeRemindersToPostLetters) }
    }
    
    var badgeRemindersToWriteLetters: Bool {
        get { bool(forKey: Key.badgeRemindersToWriteLetters) }
        set { setValue(newValue, forKey: Key.badgeRemindersToWriteLetters) }
    }
    
    var enableQuickEntry: Bool {
        get { bool(forKey: Key.enableQuickEntry) }
        set { setValue(newValue, forKey: Key.enableQuickEntry) }
    }
    
    var sendRemindersToPostLettersAtHour: Int {
        get { integer(forKey: Key.sendRemindersToPostLettersAtHour) }
        set { setValue(newValue, forKey: Key.sendRemindersToPostLettersAtHour) }
    }
    
    var sendRemindersToPostLettersAtMinute: Int {
        get { integer(forKey: Key.sendRemindersToPostLettersAtMinute) }
        set { setValue(newValue, forKey: Key.sendRemindersToPostLettersAtMinute) }
    }
    
    var stopAskingAboutContacts: Bool {
        get { bool(forKey: Key.stopAskingAboutContacts) }
        set { setValue(newValue, forKey: Key.stopAskingAboutContacts) }
    }
    
    var penpalContactMap: [String: String] {
        get {
            do {
                return try JSONDecoder().decode([String: String].self, from: data(forKey: Key.penpalContactMap) ?? Data())
            } catch {
                return [:]
            }
        }
        set {
            do {
                setValue(try JSONEncoder().encode(newValue), forKey: Key.penpalContactMap)
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
