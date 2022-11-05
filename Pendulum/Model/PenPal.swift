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

struct PenPal: Identifiable, Hashable {
    let id: String
    let givenName: String?
    let familyName: String?
    let image: Data?
    let _lastEventType: Int?
    let lastEventDate: Date?
}

extension PenPal: Codable, FetchableRecord, MutablePersistableRecord {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let givenName = Column(CodingKeys.givenName)
        static let familyName = Column(CodingKeys.familyName)
        static let image = Column(CodingKeys.image)
        static let _lastEventType = Column(CodingKeys._lastEventType)
        static let lastEventDate = Column(CodingKeys.lastEventDate)
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
    
    var initials: String {
        var initials: String = ""
        if let givenName = self.givenName {
            initials = "\(initials)\(givenName.prefix(1))"
        }
        if let familyName = self.familyName {
            initials = "\(initials)\(familyName.prefix(1))"
        }
        return initials.uppercased()
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
            dataLogger.error("Could not fetch latest event for \(id) \(fullName): \(error.localizedDescription)")
            return nil
        }
    }
    
    func createEvent(ofType type: EventType) -> Event {
        return Event(id: nil, _type: type.rawValue, date: Date(), penpalID: self.id)
    }
    
    @discardableResult func addEvent(ofType type: EventType) async -> Event? {
        let event = self.createEvent(ofType: type)
        do {
            try await AppDatabase.shared.save(event)
            try await AppDatabase.shared.updateLastEvent(for: self, with: event)
        } catch {
            dataLogger.error("Could not save event: \(error.localizedDescription)")
            return nil
        }
        return event
    }
    
}
