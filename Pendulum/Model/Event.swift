//
//  Event.swift
//  Pendulum
//
//  Created by Ben Cardy on 04/11/2022.
//

import Foundation
import GRDB

struct Event: Identifiable, Hashable {
    let id: Int64?
    let _type: Int
    let date: Date
    let penpalID: String
    let notes: String?
    let pen: String?
    let ink: String?
    let paper: String?
    
    var eventType: EventType {
        EventType(rawValue: self._type) ?? .noEvent
    }
    
    var hasNotes: Bool {
        !(self.notes?.isEmpty ?? true) || !(self.pen?.isEmpty ?? true) || !(self.ink?.isEmpty ?? true) || !(self.paper?.isEmpty ?? true)
    }
    
}

extension Event: Codable, FetchableRecord, MutablePersistableRecord {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let _type = Column(CodingKeys._type)
        static let date = Column(CodingKeys.date)
        static let notes = Column(CodingKeys.notes)
        static let pen = Column(CodingKeys.pen)
        static let ink = Column(CodingKeys.ink)
        static let paper = Column(CodingKeys.paper)
    }
    static let penpal = belongsTo(PenPal.self)
    var penpal: QueryInterfaceRequest<PenPal> {
        request(for: Event.penpal)
    }
}
