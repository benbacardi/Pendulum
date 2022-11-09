//
//  PenPal.swift
//  Pendulum
//
//  Created by Ben Cardy on 04/11/2022.
//

import Foundation
import GRDB
import SwiftUI
import UIKit
import Contacts

struct PenPal: Identifiable, Hashable {
    let id: String
    let name: String
    let initials: String
    let image: Data?
    let _lastEventType: Int?
    let lastEventDate: Date?
    let notes: String?
}

extension PenPal: Codable, FetchableRecord, MutablePersistableRecord {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let name = Column(CodingKeys.name)
        static let initials = Column(CodingKeys.initials)
        static let image = Column(CodingKeys.image)
        static let _lastEventType = Column(CodingKeys._lastEventType)
        static let lastEventDate = Column(CodingKeys.lastEventDate)
        static let notes = Column(CodingKeys.notes)
    }
    
    static let events = hasMany(Event.self)
    var events: QueryInterfaceRequest<Event> {
        request(for: PenPal.events)
    }
    
    var lastEventType: EventType {
        if let type = self._lastEventType {
            return EventType(rawValue: type) ?? .noEvent
        } else {
            return .noEvent
        }
    }
    
    var displayImage: Image? {
        if let imageData = self.image, let image = UIImage(data: imageData) {
            return Image(uiImage: image).resizable()
        }
        return nil
    }
    
    func fetchLatestEvent() async -> Event? {
        do {
            return try await AppDatabase.shared.fetchLatestEvent(for: self)
        } catch {
            dataLogger.error("Could not fetch latest event for \(id) \(name): \(error.localizedDescription)")
            return nil
        }
    }
    
    func fetchAllEvents() async -> [Event] {
        do {
            return try await AppDatabase.shared.fetchAllEvents(for: self)
        } catch {
            dataLogger.error("Could not fetch events for \(id) \(name): \(error.localizedDescription)")
            return []
        }
    }
    
    func createEvent(ofType type: EventType, notes: String? = nil, pen: String? = nil, ink: String? = nil, paper: String? = nil, forDate: Date = Date()) -> Event {
        return Event(id: nil, _type: type.rawValue, date: forDate, penpalID: self.id, notes: notes, pen: pen, ink: ink, paper: paper)
    }
    
    @discardableResult
    func addEvent(ofType type: EventType, notes: String? = nil, pen: String? = nil, ink: String? = nil, paper: String? = nil, forDate: Date = Date()) async -> Event? {
        let event = self.createEvent(ofType: type, notes: notes, pen: pen, ink: ink, paper: paper, forDate: forDate)
        do {
            try await AppDatabase.shared.save(event)
            try await AppDatabase.shared.updateLastEventType(for: self, with: event)
        } catch {
            dataLogger.error("Could not save event: \(error.localizedDescription)")
            return nil
        }
        return event
    }
    
    @discardableResult
    func updateLastEventType(with event: Event? = nil) async -> EventType {
        do {
            return try await AppDatabase.shared.updateLastEventType(for: self, with: event)
        } catch {
            dataLogger.error("Could not update last event: \(error.localizedDescription)")
            return .noEvent
        }
    }
    
    @discardableResult
    func update(from contact: CNContact) async -> Bool {
        let newPenPal = PenPal(id: self.id, name: contact.fullName ?? self.name, initials: contact.initials, image: contact.thumbnailImageData, _lastEventType: self._lastEventType, lastEventDate: self.lastEventDate, notes: self.notes)
        do {
            return try await AppDatabase.shared.updatePenPal(self, from: newPenPal)
        } catch {
            dataLogger.error("Could not update PenPal: \(error.localizedDescription)")
        }
        return false
    }
    
    @discardableResult
    func save(notes: String?) async -> Bool {
        let newPenPal = PenPal(id: self.id, name: self.name, initials: self.initials, image: self.image, _lastEventType: self._lastEventType, lastEventDate: self.lastEventDate, notes: notes)
        do {
            return try await AppDatabase.shared.updatePenPal(self, from: newPenPal)
        } catch {
            dataLogger.error("Could not update PenPal: \(error.localizedDescription)")
        }
        return false
    }
    
    func delete() async {
        do {
            try await AppDatabase.shared.delete(self)
        } catch {
            dataLogger.error("Could not delete penpal: \(error.localizedDescription)")
        }
    }
    
    func archive() async {
        do {
            try await AppDatabase.shared.setLastEventType(for: self, to: .archived, at: Date())
        } catch {
            dataLogger.error("Could not archive penpal: \(error.localizedDescription)")
        }
    }
    
}
