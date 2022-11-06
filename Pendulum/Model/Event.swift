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
    
    static var actionableCases: [EventType] {
        EventType.allCases.filter { $0 != .noEvent }
    }
    
    var description: String {
        switch self {
        case .noEvent:
            return "Nothing yet"
        case .written:
            return "You wrote a letter"
        case .sent:
            return "You sent a letter"
        case .inbound:
            return "They sent something"
        case .received:
            return "You received something"
        }
    }
    
    var icon: String {
        switch self {
        case .noEvent:
            return "hourglass"
        case .written:
            return "envelope"
        case .sent:
            return "paperplane"
        case .inbound:
            return "square.and.arrow.down"
        case .received:
            return "pencil.line"
        }
    }
    
    var phrase: String {
        switch self {
        case .noEvent:
            return "Get started!"
        case .written:
            return "You have letters to post!"
        case .sent:
            return "Waiting for a response..."
        case .inbound:
            return "Post is on its way!"
        case .received:
            return "You have letters to reply to!"
        }
    }
    
    var datePrefix: String {
        switch self {
        case .noEvent:
            return "N/A"
        case .written:
            return "You wrote to them"
        case .sent:
            return "You posted their letter"
        case .inbound:
            return "They posted their letter"
        case .received:
            return "You received their letter"
        }
    }
    
    var actionableText: String {
        switch self {
        case .noEvent:
            return ""
        case .written:
            return "I've written a letter"
        case .sent:
            return "I've posted a letter"
        case .inbound:
            return "Something's on its way"
        case .received:
            return "I've received something"
        }
    }
    
}

struct Event: Identifiable, Hashable {
    let id: Int64?
    let _type: Int
    let date: Date
    let penpalID: String
    
    var eventType: EventType {
        EventType(rawValue: self._type) ?? .noEvent
    }
    
}

extension Event: Codable, FetchableRecord, MutablePersistableRecord {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let _type = Column(CodingKeys._type)
        static let date = Column(CodingKeys.date)
    }
    static let penpal = belongsTo(PenPal.self)
    var penpal: QueryInterfaceRequest<PenPal> {
        request(for: Event.penpal)
    }
}
