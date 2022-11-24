//
//  LetterType.swift
//  Pendulum
//
//  Created by Ben Cardy on 24/11/2022.
//

import Foundation

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
            return "greetings card"
        case .package:
            return "package"
        }
    }
    
    var properNoun: String {
        switch self {
        case .letter:
            return "Letter"
        case .postcard:
            return "Postcard"
        case .greetingscard:
            return "Greetings Card"
        case .package:
            return "Package"
        }
    }
    
}
