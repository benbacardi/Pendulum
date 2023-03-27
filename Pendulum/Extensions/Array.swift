//
//  Array.swift
//  Pendulum
//
//  Created by Ben Cardy on 19/01/2023.
//

import Foundation

extension Array {
    func shiftRight(by: Int = 1) -> [Element] {
        guard count > 0 else { return self }
        var amount = by
        assert(-count...count ~= amount, "Shift amount out of bounds")
        if amount < 0 { amount += count }  // this needs to be >= 0
        return Array(self[amount ..< count] + self[0 ..< amount])
    }
}

extension Sequence where Element: Hashable {
    func uniqued() -> [Element] {
        var set = Set<Element>()
        return filter { set.insert($0).inserted }
    }
}
