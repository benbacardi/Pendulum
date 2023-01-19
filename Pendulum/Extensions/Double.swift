//
//  Double.swift
//  Pendulum
//
//  Created by Ben Cardy on 19/01/2023.
//

import Foundation

extension Double {
    func roundToDecimalPlaces(_ spaces: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = spaces
        return formatter.string(from: NSNumber(value: self))!
    }
}
