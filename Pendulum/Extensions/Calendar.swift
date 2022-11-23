//
//  Calendar.swift
//  Pendulum
//
//  Created by Ben Cardy on 06/11/2022.
//

import Foundation

let VERBOSE_NUMBER_MAPPINGS: [Int: String] = [
    1: "one",
    2: "two",
    3: "three",
    4: "four",
    5: "five",
    6: "six",
    7: "seven",
    8: "eight",
    9: "nine",
    10: "ten"
]

extension Calendar {
    func numberOfDaysBetween(_ from: Date, and to: Date) -> Int {
        let fromDate = startOfDay(for: from)
        let toDate = startOfDay(for: to)
        let numberOfDays = dateComponents([.day], from: fromDate, to: toDate)
        return numberOfDays.day!
    }
    func verboseNumberOfDaysBetween(_ from: Date, and to: Date) -> String {
        let days = numberOfDaysBetween(from, and: to)
        switch days {
        case 0:
            return "today"
        case 1:
            return "yesterday"
        default:
            let verboseDays = VERBOSE_NUMBER_MAPPINGS[days] ?? "\(days)"
            let plural = days > 1 ? "s" : ""
            return "\(verboseDays) day\(plural) ago"
        }
    }
}
