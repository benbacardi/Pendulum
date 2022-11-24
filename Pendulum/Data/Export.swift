//
//  Export.swift
//  Pendulum
//
//  Created by Ben Cardy on 22/11/2022.
//

import Foundation

struct ExportedEvent: Codable {
    let id: UUID
    let type: Int
    let date: Date
    let notes: String?
    let pen: String?
    let ink: String?
    let paper: String?
    
    init(from: Event) {
        self.id = from.id ?? UUID()
        self.type = from.type.rawValue
        self.date = from.wrappedDate
        self.notes = from.notes
        self.pen = from.pen
        self.ink = from.ink
        self.paper = from.paper
    }
    
}

struct ExportedPenPal: Codable {
    let id: UUID
    let name: String
    let initials: String
    let image: Data?
    let notes: String?
    let archived: Bool
    let events: [ExportedEvent]
    
    init(from: PenPal) {
        self.id = from.id ?? UUID()
        self.name = from.wrappedName
        self.initials = from.wrappedInitials
        self.image = from.image
        self.notes = from.notes
        self.archived = from.archived
        self.events = from.allEvents.map { ExportedEvent(from: $0) }
    }
    
}

struct ExportedStationery: Codable {
    let id: UUID
    let type: String
    let value: String
    
    init(from: Stationery) {
        self.id = from.id ?? UUID()
        self.type = from.wrappedType
        self.value = from.wrappedValue
    }
    
}

struct Export: Codable {
    let penpals: [ExportedPenPal]
    let stationery: [ExportedStationery]
    
    let version: Int = 1
    
    init(penpals: [PenPal], stationery: [Stationery]) {
        self.penpals = penpals.map { ExportedPenPal(from: $0) }
        self.stationery = stationery.map { ExportedStationery(from: $0) }
    }
    
}
