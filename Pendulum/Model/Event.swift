//
//  Event.swift
//  Pendulum
//
//  Created by Ben Cardy on 04/11/2022.
//

import Foundation
import GRDB
import CloudKit

struct Event: Identifiable, Hashable {
    var id: Int64?
    var _type: Int
    var date: Date
    var penpalID: String
    var notes: String?
    var pen: String?
    var ink: String?
    var paper: String?
    var lastUpdated: Date?
    var dateDeleted: Date?
    var cloudKitID: String?
    
    var eventType: EventType {
        EventType(rawValue: self._type) ?? .noEvent
    }
    
    var hasNotes: Bool {
        !(self.notes?.isEmpty ?? true) || self.hasAttributes
    }
    
    var hasAttributes: Bool {
        !(self.pen?.isEmpty ?? true) || !(self.ink?.isEmpty ?? true) || !(self.paper?.isEmpty ?? true)
    }
    
}

extension Event: CloudKitSyncedModel {
    static let cloudKitRecordType: String = "Event"
    
    func convertToCKRecord() -> CKRecord {
        let record: CKRecord
        if let cloudKitID = self.cloudKitID {
            record = CKRecord(recordType: Event.cloudKitRecordType, recordID: CKRecord.ID(recordName: cloudKitID))
        } else {
            record = CKRecord(recordType: Event.cloudKitRecordType)
        }
        record["type"] = self._type
        record[Columns.date.name] = self.date
        record[Columns.penpalID.name] = self.penpalID
        record[Columns.notes.name] = self.notes
        record[Columns.pen.name] = self.pen
        record[Columns.ink.name] = self.ink
        record[Columns.paper.name] = self.paper
        record[Columns.lastUpdated.name] = self.lastUpdated
        record[Columns.dateDeleted.name] = self.dateDeleted
        return record
    }
    
    init(from record: CKRecord) throws {
        self.cloudKitID = record.recordID.recordName
        guard let recordType = record["type"] as? Int else { cloudKitLogger.error("No type"); throw PenPalError() }
        guard let recordDate = record[Columns.date.name] as? Date else { cloudKitLogger.error("No date"); throw PenPalError() }
        guard let recordPenPalID = record[Columns.penpalID.name] as? String else { cloudKitLogger.error("No penpal ID"); throw PenPalError() }
        guard let recordLastUpdated = record[Columns.lastUpdated.name] as? Date else { cloudKitLogger.error("No date"); throw PenPalError() }
        self.id = nil
        self._type = recordType
        self.date = recordDate
        self.penpalID = recordPenPalID
        self.notes = record[Columns.notes.name]
        self.pen = record[Columns.pen.name]
        self.ink = record[Columns.ink.name]
        self.paper = record[Columns.paper.name]
        self.lastUpdated = recordLastUpdated
        self.dateDeleted = record[Columns.dateDeleted.name]
    }
    
    static func create(from record: CKRecord) async throws {
        let new = try Event(from: record)
        try await AppDatabase.shared.save(new)
    }
    
    func update(from record: CKRecord) async throws {
        var new = try Event(from: record)
        new.id = self.id
        try await AppDatabase.shared.update(self, from: new)
    }
    
    func setCloudKitID(to cloudKitID: String) async {
        do {
            try await AppDatabase.shared.setCloudKitId(for: self, to: cloudKitID)
        } catch {
            dataLogger.error("Could not update CloudKit ID: \(error.localizedDescription)")
        }
    }
    
    var description: String { "\(self.date): \(self.penpalID) \(self._type)" }
    
    static func fetchUnsynced() async -> [Event] {
        do {
            return try await AppDatabase.shared.fetchUnsyncedEvents()
        } catch {
            dataLogger.error("Could not fetch unsynced Event: \(error.localizedDescription)")
            return []
        }
    }
    
    static func fetchSynced() async -> [Event] {
        do {
            return try await AppDatabase.shared.fetchSyncedEvents()
        } catch {
            dataLogger.error("Could not fetch synced Event: \(error.localizedDescription)")
            return []
        }
    }
    
}

extension Event: Codable, FetchableRecord, MutablePersistableRecord {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let _type = Column(CodingKeys._type)
        static let penpalID = Column(CodingKeys.penpalID)
        static let date = Column(CodingKeys.date)
        static let notes = Column(CodingKeys.notes)
        static let pen = Column(CodingKeys.pen)
        static let ink = Column(CodingKeys.ink)
        static let paper = Column(CodingKeys.paper)
        static let lastUpdated = Column(CodingKeys.lastUpdated)
        static let dateDeleted = Column(CodingKeys.dateDeleted)
        static let cloudKitID = Column(CodingKeys.cloudKitID)
    }
    static let penpal = belongsTo(PenPal.self)
    var penpal: QueryInterfaceRequest<PenPal> {
        request(for: Event.penpal)
    }
    
    func clone() -> Event {
        Event(
            id: self.id,
            _type: self._type,
            date: self.date,
            penpalID: self.penpalID,
            notes: self.notes,
            pen: self.pen,
            ink: self.ink,
            paper: self.paper,
            lastUpdated: self.lastUpdated,
            dateDeleted: self.dateDeleted,
            cloudKitID: self.cloudKitID
        )
    }
    
    @discardableResult
    func update(from newEvent: Event) async -> Bool {
        do {
            let response = try await AppDatabase.shared.update(self, from: newEvent)
            CloudKitController.triggerSyncRequiredNotification()
            return response
        } catch {
            dataLogger.error("Could not update Event: \(error.localizedDescription)")
        }
        return false
    }
    
    func delete() async -> EventType {
        do {
            let penpal = try await AppDatabase.shared.penPalFor(event: self)
            var updatedEvent = self.clone()
            updatedEvent.dateDeleted = Date()
            updatedEvent.lastUpdated = updatedEvent.dateDeleted
            do {
                try await AppDatabase.shared.update(self, from: updatedEvent)
                CloudKitController.triggerSyncRequiredNotification()
                if let penpal = penpal {
                    return try await AppDatabase.shared.updateLastEventType(for: penpal)
                }
            } catch {
                dataLogger.error("Could not delete event: \(error.localizedDescription)")
            }
        } catch {
            dataLogger.error("Could not fetch PenPal for event: \(error.localizedDescription)")
        }
        return .noEvent
    }
    
}
