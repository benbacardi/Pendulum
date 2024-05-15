//
//  AppStorage.swift
//  Pendulum
//
//  Created by Ben Cardy on 04/05/2024.
//

import SwiftUI

extension AppStorage {
    init(wrappedValue: Value, _ key: UserDefaults.Key, store: UserDefaults? = nil) where Value == Bool {
        self.init(wrappedValue: wrappedValue, key.rawValue, store: store)
    }

    init(wrappedValue: Value, _ key: UserDefaults.Key, store: UserDefaults? = nil) where Value == Int {
        self.init(wrappedValue: wrappedValue, key.rawValue, store: store)
    }

    init(wrappedValue: Value, _ key: UserDefaults.Key, store: UserDefaults? = nil) where Value == Double {
        self.init(wrappedValue: wrappedValue, key.rawValue, store: store)
    }

    init(wrappedValue: Value, _ key: UserDefaults.Key, store: UserDefaults? = nil) where Value == String {
        self.init(wrappedValue: wrappedValue, key.rawValue, store: store)
    }

    init(wrappedValue: Value, _ key: UserDefaults.Key, store: UserDefaults? = nil) where Value == URL {
        self.init(wrappedValue: wrappedValue, key.rawValue, store: store)
    }

    init(wrappedValue: Value, _ key: UserDefaults.Key, store: UserDefaults? = nil) where Value == Data {
        self.init(wrappedValue: wrappedValue, key.rawValue, store: store)
    }
   
    init(wrappedValue: Value, _ key: UserDefaults.Key, store: UserDefaults? = nil) where Value : RawRepresentable, Value.RawValue == Int {
        self.init(wrappedValue: wrappedValue, key.rawValue, store: store)
    }

    init(wrappedValue: Value, _ key: UserDefaults.Key, store: UserDefaults? = nil) where Value : RawRepresentable, Value.RawValue == String {
        self.init(wrappedValue: wrappedValue, key.rawValue, store: store)
    }
    
    init(_ key: UserDefaults.Key, store: UserDefaults? = nil) where Value == Int? {
        self.init(key.rawValue, store: store)
    }
    
    init(_ key: UserDefaults.Key, store: UserDefaults? = nil) where Value == Double? {
        self.init(key.rawValue, store: store)
    }
    
    init(_ key: UserDefaults.Key, store: UserDefaults? = nil) where Value == String? {
        self.init(key.rawValue, store: store)
    }
    
    init(_ key: UserDefaults.Key, store: UserDefaults? = nil) where Value == Bool? {
        self.init(key.rawValue, store: store)
    }
    
    init<R>(_ key: UserDefaults.Key, store: UserDefaults? = nil) where Value == R?, R : RawRepresentable, R.RawValue == Int {
        self.init(key.rawValue, store: store)
    }
    
    init<R>(_ key: UserDefaults.Key, store: UserDefaults? = nil) where Value == R?, R : RawRepresentable, R.RawValue == String {
        self.init(key.rawValue, store: store)
    }
    
    init(_ key: UserDefaults.Key, store: UserDefaults? = nil) where Value == Data? {
        self.init(key.rawValue, store: store)
    }
    
    init(_ key: UserDefaults.Key, store: UserDefaults? = nil) where Value == URL? {
        self.init(key.rawValue, store: store)
    }
}
