//
//  Event.swift
//  Pendulum
//
//  Created by Ben Cardy on 04/11/2022.
//

import Foundation
import GRDB

enum EventType: Int, CaseIterable {
    case written = 1
    case received = 2
    case inbound = 3
    case sent = 4
    
    case noEvent = 99
    
    var description: String {
        switch self {
        case .noEvent:
            return "Nothing yet"
        case .written:
            return "Written"
        case .sent:
            return "Sent"
        case .inbound:
            return "Inbound"
        case .received:
            return "Received"
        }
    }
    
}

struct Event: Identifiable, Hashable {
    let id: Int64?
    let type: Int
    let date: Date
    let penpalID: String
    
    var eventType: EventType {
        EventType(rawValue: self.type) ?? .noEvent
    }
    
}

extension Event: Codable, FetchableRecord, MutablePersistableRecord {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let type = Column(CodingKeys.type)
        static let date = Column(CodingKeys.date)
    }
    static let penpal = belongsTo(PenPal.self)
    var penpal: QueryInterfaceRequest<PenPal> {
        request(for: Event.penpal)
    }
}
