//
//  Stationery.swift
//  Pendulum
//
//  Created by Ben Cardy on 14/11/2022.
//

import Foundation
import GRDB

struct Stationery: Identifiable, Hashable {
    let id: Int64?
    let type: String
    let value: String
}

extension Stationery: Codable, FetchableRecord, MutablePersistableRecord {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let type = Column(CodingKeys.type)
        static let value = Column(CodingKeys.value)
    }
}
