//
//  Date.swift
//  Pendulum
//
//  Created by Ben Cardy on 18/01/2023.
//

import Foundation

enum Weekday: Int, CaseIterable {
    case sun = 1
    case mon = 2
    case tue = 3
    case wed = 4
    case thu = 5
    case fri = 6
    case sat = 7
    
    var shortName: String {
        return Calendar.current.shortWeekdaySymbols[self.rawValue - 1]
    }
    
    static var orderedCases: [Weekday] {
        Self.allCases.shiftRight(by: Calendar.current.firstWeekday - 1)
    }
}

extension Date {
    var dayNumberOfWeek: Int? {
        return Calendar.current.dateComponents([.weekday], from: self).weekday
    }
    
    var weekday: Weekday {
        return Weekday(rawValue: dayNumberOfWeek ?? 0) ?? .sun
    }
    
}
