//
//  EventModel.swift
//  Pendulum
//
//  Created by Ben Cardy on 19/04/2024.
//

import Foundation

struct EventModel: Identifiable, Equatable {
    let id: UUID
    let date: Date
    let type: EventType
    let letterType: LetterType
    let notes: String?
    let noFurtherActions: Bool
    let noResponseNeeded: Bool
    let paper: [String]
    let pens: [String]
    let ink: [String]
    let trackingReference: String?
    var photos: [String] = []
    
    var hasNotesOrAttributes: Bool {
        !(self.notes?.isEmpty ?? true) || self.hasAttributes
    }
    
    var hasAttributes: Bool {
        self.hasStationery || !(self.trackingReference?.isEmpty ?? true)
    }
    
    var hasStationery: Bool {
        !self.pens.isEmpty || !self.ink.isEmpty || !self.paper.isEmpty
    }
}

struct EventSection: Identifiable {
    var id: UUID = UUID()
    let dayInterval: Int
    var events: [EventModel]
    var calculatedFromToday: Bool = false
    
    func removingEvent(_ event: EventModel) -> EventSection {
        if events.contains(event) {
            return EventSection(
                id: id,
                dayInterval: dayInterval,
                events: events.filter { $0.id != event.id },
                calculatedFromToday: calculatedFromToday
            )
        }
        return self
    }
}
