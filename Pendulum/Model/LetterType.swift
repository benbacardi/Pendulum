//
//  LetterType.swift
//  Pendulum
//
//  Created by Ben Cardy on 24/11/2022.
//

import Foundation
import Charts

enum LetterType: Int, CaseIterable, Identifiable {
    case letter = 0
    case postcard = 1
    case greetingscard = 2
    case package = 3
    
    var id: Int { self.rawValue }
    
    static func from(_ value: Int16) -> LetterType {
        LetterType(rawValue: Int(value)) ?? .letter
    }
    
    var description: String {
        switch self {
        case .letter:
            return "letter"
        case .postcard:
            return "postcard"
        case .greetingscard:
            return "card"
        case .package:
            return "parcel"
        }
    }
    
    var properNoun: String {
        switch self {
        case .letter:
            return "Letter"
        case .postcard:
            return "Postcard"
        case .greetingscard:
            return "Card"
        case .package:
            return "Parcel"
        }
    }
    
    var icon: String {
        switch self {
        case .letter:
            return "envelope"
        case .postcard:
            return "photo"
        case .greetingscard:
            return "greetingcard"
        case .package:
            return "shippingbox"
        }
    }
    
    var defaultIgnore: Bool {
        switch self {
        case .letter:
            return false
        default:
            return true
        }
    }
    
}

extension LetterType: Plottable {
    var primitivePlottable: String {
        properNoun
    }
    init?(primitivePlottable: String) {
        nil
    }
}
