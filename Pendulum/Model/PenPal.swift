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
    var id: String
    var contactID: String?
    var name: String
    var initials: String
    var image: Data?
    var _lastEventType: Int?
    var lastEventDate: Date?
    var notes: String?
    var archived: Bool = false
    var lastUpdated: Date?
    var dateDeleted: Date?
    var cloudKitID: String?
}

struct PenPalError: Error { }

extension PenPal: CloudKitSyncedModel {
    
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
        record[Columns.archived.name] = self.archived
        record[Columns.initials.name] = self.initials
        record[Columns.image.name] = self.image
        record[Columns.notes.name] = self.notes
        record[Columns.lastUpdated.name] = self.lastUpdated
        record[Columns.dateDeleted.name] = self.dateDeleted
        return record
    }
    
    init(from record: CKRecord) throws {
        self.cloudKitID = record.recordID.recordName
        guard let recordID = record[Columns.id.name] as? String else { cloudKitLogger.error("No id"); throw PenPalError() }
        guard let recordName = record[Columns.name.name] as? String else { cloudKitLogger.error("No name"); throw PenPalError() }
        guard let recordInitials = record[Columns.initials.name] as? String else { cloudKitLogger.error("No initials"); throw PenPalError() }
        guard let recordLastUpdated = record[Columns.lastUpdated.name] as? Date else { cloudKitLogger.error("No date"); throw PenPalError() }
        self.id = recordID
        self.contactID = nil
        self.name = recordName
        self.initials = recordInitials
        self.image = record[Columns.image.name]
        self.notes = record[Columns.notes.name]
        self.archived = record[Columns.archived.name] as? Bool ?? false
        self.lastUpdated = recordLastUpdated
        self.dateDeleted = record[Columns.dateDeleted.name]
        self._lastEventType = nil
        self.lastEventDate = nil
    }
    
    static func create(from record: CKRecord) async throws {
        let new = try PenPal(from: record)
        try await AppDatabase.shared.save(new)
    }
    
    func update(from record: CKRecord) async throws {
        var new = try PenPal(from: record)
        new._lastEventType = self._lastEventType
        new.lastEventDate = self.lastEventDate
        try await AppDatabase.shared.update(self, from: new)
    }
    
    func setCloudKitID(to cloudKitID: String) async {
        do {
            try await AppDatabase.shared.setCloudKitId(for: self, to: cloudKitID)
        } catch {
            dataLogger.error("Could not update CloudKit ID: \(error.localizedDescription)")
        }
    }
    
    var description: String { self.name }
    
    static func fetchUnsynced() async -> [PenPal] {
        do {
            return try await AppDatabase.shared.fetchUnsyncedPenPals()
        } catch {
            dataLogger.error("Could not fetch unsynced PenPals: \(error.localizedDescription)")
            return []
        }
    }
    
    static func fetchSynced() async -> [PenPal] {
        do {
            return try await AppDatabase.shared.fetchSyncedPenPals()
        } catch {
            dataLogger.error("Could not fetch synced PenPals: \(error.localizedDescription)")
            return []
        }
    }
    
}

extension PenPal: Codable, FetchableRecord, MutablePersistableRecord {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let contactID = Column(CodingKeys.contactID)
        static let name = Column(CodingKeys.name)
        static let initials = Column(CodingKeys.initials)
        static let image = Column(CodingKeys.image)
        static let _lastEventType = Column(CodingKeys._lastEventType)
        static let lastEventDate = Column(CodingKeys.lastEventDate)
        static let notes = Column(CodingKeys.notes)
        static let archived = Column(CodingKeys.archived)
        static let lastUpdated = Column(CodingKeys.lastUpdated)
        static let dateDeleted = Column(CodingKeys.dateDeleted)
        static let cloudKitID = Column(CodingKeys.cloudKitID)
    }
    
    static let events = hasMany(Event.self)
    var events: QueryInterfaceRequest<Event> {
        request(for: PenPal.events.filter(Event.Columns.dateDeleted == nil))
    }
    
    var allEvents: QueryInterfaceRequest<Event> {
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
    
    func clone() -> PenPal {
        PenPal(
            id: self.id,
            contactID: self.contactID,
            name: self.name,
            initials: self.initials,
            image: self.image,
            _lastEventType: self._lastEventType,
            lastEventDate: self.lastEventDate,
            notes: self.notes,
            archived: self.archived,
            lastUpdated: self.lastUpdated,
            dateDeleted: self.dateDeleted,
            cloudKitID: self.cloudKitID
        )
    }
    
    func fetchLatestEvent() async -> Event? {
        do {
            return try await AppDatabase.shared.fetchLatestEvent(for: self)
        } catch {
            dataLogger.error("Could not fetch latest event for \(name): \(error.localizedDescription)")
            return nil
        }
    }
    
    func fetchAllEvents() async -> [Event] {
        do {
            return try await AppDatabase.shared.fetchAllEvents(for: self)
        } catch {
            dataLogger.error("Could not fetch events for \(name): \(error.localizedDescription)")
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
        return Event(id: nil, _type: type.rawValue, date: forDate, penpalID: self.id, notes: notes, pen: pen, ink: ink, paper: paper, lastUpdated: Date(), dateDeleted: nil, cloudKitID: nil)
    }
    
    @discardableResult
    func addEvent(ofType type: EventType, notes: String? = nil, pen: String? = nil, ink: String? = nil, paper: String? = nil, forDate: Date = Date()) async -> Event? {
        let event = self.createEvent(ofType: type, notes: notes, pen: pen, ink: ink, paper: paper, forDate: forDate)
        do {
            try await AppDatabase.shared.save(event)
            try await AppDatabase.shared.updateLastEventType(for: self)
            CloudKitController.triggerSyncRequiredNotification()
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
    
    init(from contact: CNContact) {
        self.id = UUID().uuidString
        self.contactID = contact.identifier
        self.name = contact.fullName ?? "Unknown Contact"
        self.initials = contact.initials
        self.image = contact.thumbnailImageData
        self._lastEventType = EventType.noEvent.rawValue
        self.lastEventDate = nil
        self.notes = nil
        self.lastUpdated = Date()
        self.dateDeleted = nil
        self.cloudKitID = nil
    }
    
    @discardableResult
    func update(from contact: CNContact) async -> Bool {
        let image = contact.thumbnailImageData
        let initials = contact.initials
        let name = contact.fullName ?? self.name
        let contactID = contact.identifier
        if image != self.image || initials != self.initials || name != self.name || contactID != self.contactID {
            var newPenPal = self.clone()
            newPenPal.contactID = contactID
            newPenPal.image = image
            newPenPal.initials = initials
            newPenPal.name = name
            if image != self.image || initials != self.initials || name != self.name {
                newPenPal.lastUpdated = Date()
            }
            do {
                let response = try await AppDatabase.shared.update(self, from: newPenPal)
                if newPenPal.lastUpdated != self.lastUpdated {
                    CloudKitController.triggerSyncRequiredNotification()
                }
                return response
            } catch {
                dataLogger.error("Could not update PenPal: \(error.localizedDescription)")
                return false
            }
        }
        return true
    }
    
    @discardableResult
    func save(notes: String?) async -> Bool {
        if self.notes == notes { return true }
        var newPenPal = self.clone()
        newPenPal.notes = notes
        newPenPal.lastUpdated = Date()
        do {
            return try await AppDatabase.shared.update(self, from: newPenPal)
            CloudKitController.triggerSyncRequiredNotification()
        } catch {
            dataLogger.error("Could not update PenPal: \(error.localizedDescription)")
        }
        return false
    }
    
    func save() async throws {
        try await AppDatabase.shared.save(self)
    }
    
    func delete() async {
        var newPenPal = self.clone()
        newPenPal.dateDeleted = Date()
        newPenPal.lastUpdated = newPenPal.dateDeleted
        do {
            try await AppDatabase.shared.update(self, from: newPenPal)
            try await AppDatabase.shared.deleteEvents(for: newPenPal)
            CloudKitController.triggerSyncRequiredNotification()
        } catch {
            dataLogger.error("Could not delete penpal: \(error.localizedDescription)")
        }
    }
    
    func archive(_ value: Bool = true) async {
        var newPenPal = self.clone()
        newPenPal.archived = value
        newPenPal.lastUpdated = Date()
        do {
            try await AppDatabase.shared.update(self, from: newPenPal)
            CloudKitController.triggerSyncRequiredNotification()
        } catch {
            dataLogger.error("Could not \(value ? "" : "un")archive penpal: \(error.localizedDescription)")
        }
    }
    
    func unarchive() async {
        await self.archive(false)
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
