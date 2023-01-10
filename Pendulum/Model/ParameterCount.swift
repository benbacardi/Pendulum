//
//  ParameterCount.swift
//  Pendulum
//
//  Created by Ben Cardy on 09/01/2023.
//

import Foundation

struct ParameterCount: Comparable {
    let name: String
    let count: Int
    
    static func < (lhs: ParameterCount, rhs: ParameterCount) -> Bool {
        if lhs.count != rhs.count {
            return lhs.count > rhs.count
        } else {
            return lhs.name < rhs.name
        }
    }
    
    static func == (lhs: ParameterCount, rhs: ParameterCount) -> Bool {
        return lhs.count == rhs.count && lhs.name == rhs.name
    }
    
}
