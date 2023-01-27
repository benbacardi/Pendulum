//
//  Date.swift
//  Pendulum
//
//  Created by Ben Cardy on 18/01/2023.
//

import Foundation
import Charts

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

enum Month: Int, CaseIterable, Plottable {
    case january = 1
    case february = 2
    case march = 3
    case april = 4
    case may = 5
    case june = 6
    case july = 7
    case august = 8
    case september = 9
    case october = 10
    case november = 11
    case december = 12
    
    var shortName: String {
        Calendar.current.shortMonthSymbols[self.rawValue - 1]
    }
    
    var primitivePlottable: String { shortName }
    init?(primitivePlottable: String) {
        self.init(rawValue: Calendar.current.shortMonthSymbols.firstIndex(of: primitivePlottable) ?? 0)
    }
    
}

extension Date {
    
    var dayNumberOfWeek: Int? {
        return Calendar.current.dateComponents([.weekday], from: self).weekday
    }
    
    var monthNumber: Int? {
        return Calendar.current.dateComponents([.month], from: self).month
    }
    
    var weekday: Weekday {
        return Weekday(rawValue: dayNumberOfWeek ?? 0) ?? .sun
    }
    
    var month: Month {
        return Month(rawValue: monthNumber ?? 0) ?? .january
    }
    
}
