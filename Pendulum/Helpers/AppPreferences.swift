//
//  AppPreferences.swift
//  Pendulum
//
//  Created by Ben Cardy on 27/01/2023.
//

import Foundation
import SwiftUI

class AppPreferences: ObservableObject {
    
    static var shared = AppPreferences()
    
    @AppStorage(UserDefaults.Key.trackPostingLetters, store: UserDefaults.shared) var trackPostingLetters = true {
        didSet {
            objectWillChange.send()
        }
    }
    
}
