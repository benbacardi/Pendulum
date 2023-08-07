//
//  UIColor.swift
//  Pendulum
//
//  Created by Ben Cardy on 01/08/2023.
//

import Foundation
import SwiftUI
import UIKit

public extension UIColor {
    
    func lighter(by percentage: CGFloat = 30.0) -> UIColor? {
        return self.adjust(by: abs(percentage) )
    }
    
    func darker(by percentage: CGFloat = 30.0) -> UIColor? {
        return self.adjust(by: -1 * abs(percentage) )
    }
    
    func adjust(by percentage: CGFloat = 30.0) -> UIColor? {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        if self.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            return UIColor(red: min(red + percentage/100, 1.0),
                           green: min(green + percentage/100, 1.0),
                           blue: min(blue + percentage/100, 1.0),
                           alpha: alpha)
        } else {
            return nil
        }
    }

}

public extension Color {
    static var random: Color {
        return Color(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1)
        )
    }
    
    func darker(by percentage: CGFloat = 30.0) -> Color {
        return Color(UIColor(self).darker(by: percentage) ?? UIColor.red)
    }
    
    func lighter(by percentage: CGFloat = 30.0) -> Color {
        return Color(UIColor(self).lighter(by: percentage) ?? UIColor.red)
    }
    
}
