//
//  PenPal.swift
//  Pendulum
//
//  Created by Ben Cardy on 04/11/2022.
//

import Foundation
import GRDB

struct PenPal: Identifiable, Hashable {
    let id: String
    let givenName: String?
    let familyName: String?
    let image: Data?
}

extension PenPal: Codable, FetchableRecord, MutablePersistableRecord {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let givenName = Column(CodingKeys.givenName)
        static let familyName = Column(CodingKeys.familyName)
        static let image = Column(CodingKeys.image)
    }
    
    static let events = hasMany(Event.self)
    var events: QueryInterfaceRequest<Event> {
        request(for: PenPal.events)
    }
    
    var fullName: String {
        var parts: [String] = []
        if let givenName = self.givenName {
            parts.append(givenName)
        }
        if let familyName = self.familyName {
            parts.append(familyName)
        }
        return parts.joined(separator: " ")
    }
    
    func fetchLatestEvent() async -> Event? {
        do {
            return try await AppDatabase.shared.fetchLatestEvent(for: self)
        } catch {
            dataLogger.error("Could not fetch latest event for \(id) \(fullName): \(error.localizedDescription)")
            return nil
        }
    }
    
    func createEvent(ofType type: EventType) -> Event {
        return Event(id: nil, type: type.rawValue, date: Date(), penpalID: self.id)
    }
    
    @discardableResult func addEvent(ofType type: EventType) async -> Event? {
        let event = self.createEvent(ofType: type)
        do {
            try await AppDatabase.shared.save(event)
        } catch {
            dataLogger.error("Could not save event: \(error.localizedDescription)")
            return nil
        }
        return event
    }
    
}
