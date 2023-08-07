//
//  AppInfo.swift
//  Pendulum
//
//  Created by Ben Cardy on 04/11/2022.
//

import Foundation
import SwiftUI
import WidgetKit

let APP_GROUP = "group.uk.co.bencardy.Pendulum"

enum Tab: Int {
    case penPalList
    case settings
    case stats
}

extension Color {
    static let adequatelyGinger = Color(UIColor(red: 251 / 255, green: 171 / 255, blue: 57 / 255, alpha: 1))
}

enum WidgetType: String {
    case NonInteractiveWidget
    
    func reload() {
        appLogger.debug("Reloading widget of type \(self.rawValue)")
        WidgetCenter.shared.reloadTimelines(ofKind: self.rawValue)
    }
    
    static func reload() {
        appLogger.debug("Reloading all widgets")
        WidgetCenter.shared.reloadAllTimelines()
    }
    
}
