//
//  AppPreferences.swift
//  Pendulum
//
//  Created by Ben Cardy on 27/01/2023.
//

import Foundation
import WidgetKit
import SwiftUI

class AppPreferences: ObservableObject {
    
    static var shared = AppPreferences()
    
    @AppStorage(UserDefaults.Key.trackPostingLetters.rawValue, store: UserDefaults.shared) var trackPostingLetters = true {
        didSet {
            objectWillChange.send()
//            WidgetType.NonInteractiveWidget.reload()
        }
    }
    
}
