//
//  NSUbiquitousKeyValueStore.swift
//  Pendulum
//
//  Created by Ben Cardy on 04/02/2023.
//

import Foundation

extension NSUbiquitousKeyValueStore {
    
    func add(tip: TipJar) {
        set(Double(fetchCount(forTip: tip) + 1), forKey: tip.rawValue)
        self.synchronize()
    }
    
    func fetchCount(forTip tip: TipJar) -> Int {
        Int(double(forKey: tip.rawValue))
    }
    
    func fetchAllTipCounts() -> [TipJar: Int] {
        var results: [TipJar: Int] = [:]
        for tip in TipJar.allCases {
            let res = fetchCount(forTip: tip)
            if res != 0 {
                results[tip] = res
            }
        }
        return results
    }
    
}
