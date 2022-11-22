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
}

struct ExportedStationery: Codable {
    let id: UUID
    let type: String
    let value: String
}

struct Export: Codable {
    let penpals: [ExportedPenPal]
    let stationery: [ExportedStationery]
}
