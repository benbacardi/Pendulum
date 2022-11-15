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
import CloudKit

struct PenPal: Identifiable, Hashable {
    let id: String
    let name: String
    let initials: String
    let image: Data?
    let _lastEventType: Int?
    let lastEventDate: Date?
    let notes: String?
    let lastUpdated: Date?
    let dateDeleted: Date?
    let cloudKitID: String?
}

struct PenPalError: Error { }

extension PenPal {
    
    static let cloudKitRecordType: String = "PenPal"
    
    func convertToCKRecord() -> CKRecord {
        let record: CKRecord
        if let cloudKitID = self.cloudKitID {
            record = CKRecord(recordType: PenPal.cloudKitRecordType, recordID: CKRecord.ID(recordName: cloudKitID))
        } else {
            record = CKRecord(recordType: PenPal.cloudKitRecordType)
        }
        record[Columns.id.name] = self.id
        record[Columns.name.name] = self.name
        record[Columns.initials.name] = self.initials
        record[Columns.image.name] = self.image ?? Data()
        record[Columns.notes.name] = self.notes
        record[Columns.lastUpdated.name] = self.lastUpdated ?? .distantPast
        record[Columns.dateDeleted.name] = self.dateDeleted ?? .distantPast
        return record
    }
    
    init(from record: CKRecord, lastEventType: EventType? = nil, lastEventDate: Date? = nil) throws {
        self.cloudKitID = record.recordID.recordName
        guard let recordID = record[Columns.id.name] as? String else { cloudKitLogger.error("No id"); throw PenPalError() }
        guard let recordName = record[Columns.name.name] as? String else { cloudKitLogger.error("No name"); throw PenPalError() }
        guard let recordInitials = record[Columns.initials.name] as? String else { cloudKitLogger.error("No initials"); throw PenPalError() }
        guard let recordImage = record[Columns.image.name] as? Data else { cloudKitLogger.error("No image"); throw PenPalError() }
        guard let recordLastUpdated = record[Columns.lastUpdated.name] as? Date else { cloudKitLogger.error("No date"); throw PenPalError() }
        self.id = recordID
        self.name = recordName
        self.initials = recordInitials
        self.image = recordImage
        self.notes = record[Columns.notes.name]
        self.lastUpdated = recordLastUpdated
        self.dateDeleted = record[Columns.dateDeleted.name]
        self._lastEventType = lastEventType?.rawValue
        self.lastEventDate = lastEventDate
    }
    
    func setCloudKitId(to cloudKitID: String) async {
        do {
            try await AppDatabase.shared.setCloudKitId(for: self, to: cloudKitID)
        } catch {
            dataLogger.error("Could not update CloudKit ID: \(error.localizedDescription)")
        }
    }
    
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
        static let lastUpdated = Column(CodingKeys.lastUpdated)
        static let dateDeleted = Column(CodingKeys.dateDeleted)
        static let cloudKitID = Column(CodingKeys.cloudKitID)
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
    
    func fetchPriorEvent(to date: Date, ofType eventType: EventType) async -> Event? {
        do {
            return try await AppDatabase.shared.fetchPriorEvent(to: date, ofType: eventType, for: self)
        } catch {
            dataLogger.error("Could not fetch prior event: \(error.localizedDescription)")
            return nil
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
            try await AppDatabase.shared.updateLastEventType(for: self)
        } catch {
            dataLogger.error("Could not save event: \(error.localizedDescription)")
            return nil
        }
        return event
    }
    
    @discardableResult
    func updateLastEventType(with event: Event? = nil) async -> EventType {
        do {
            return try await AppDatabase.shared.updateLastEventType(for: self)
        } catch {
            dataLogger.error("Could not update last event: \(error.localizedDescription)")
            return .noEvent
        }
    }
    
    @discardableResult
    func update(from contact: CNContact) async -> Bool {
        let image = contact.thumbnailImageData
        let initials = contact.initials
        let name = contact.fullName ?? self.name
        if image != self.image || initials != self.initials || name != self.name {
            let newPenPal = PenPal(id: self.id, name: name, initials: initials, image: image, _lastEventType: self._lastEventType, lastEventDate: self.lastEventDate, notes: self.notes, lastUpdated: Date(), dateDeleted: self.dateDeleted, cloudKitID: self.cloudKitID)
            do {
                return try await AppDatabase.shared.updatePenPal(self, from: newPenPal)
            } catch {
                dataLogger.error("Could not update PenPal: \(error.localizedDescription)")
                return false
            }
        }
        return true
    }
    
    @discardableResult
    func save(notes: String?) async -> Bool {
        let newPenPal = PenPal(id: self.id, name: self.name, initials: self.initials, image: self.image, _lastEventType: self._lastEventType, lastEventDate: self.lastEventDate, notes: notes, lastUpdated: Date(), dateDeleted: self.dateDeleted, cloudKitID: self.cloudKitID)
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
    
    func refresh() async -> PenPal? {
        do {
            return try await AppDatabase.shared.fetchPenPal(withId: self.id)
        } catch {
            dataLogger.error("Could not refresh PenPal")
            return nil
        }
    }
    
}
