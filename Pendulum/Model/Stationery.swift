//
//  Stationery.swift
//  Pendulum
//
//  Created by Ben Cardy on 14/11/2022.
//

import Foundation
import GRDB
import CloudKit

struct Stationery: Identifiable, Hashable {
    var id: Int64?
    var type: String
    var value: String
    var lastUpdated: Date?
    var dateDeleted: Date?
    var cloudKitID: String?
}

extension Stationery: Codable, FetchableRecord, MutablePersistableRecord {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let type = Column(CodingKeys.type)
        static let value = Column(CodingKeys.value)
        static let lastUpdated = Column(CodingKeys.lastUpdated)
        static let dateDeleted = Column(CodingKeys.dateDeleted)
        static let cloudKitID = Column(CodingKeys.cloudKitID)
    }
}

extension Stationery: CloudKitSyncedModel {
    static let cloudKitRecordType: String = "Stationery"
    
    func convertToCKRecord() -> CKRecord {
        let record: CKRecord
        if let cloudKitID = self.cloudKitID {
            record = CKRecord(recordType: Stationery.cloudKitRecordType, recordID: CKRecord.ID(recordName: cloudKitID))
        } else {
            record = CKRecord(recordType: Stationery.cloudKitRecordType)
        }
        record[Columns.type.name] = self.type
        record[Columns.value.name] = self.value
        record[Columns.lastUpdated.name] = self.lastUpdated
        record[Columns.dateDeleted.name] = self.dateDeleted
        return record
    }
    
    init(from record: CKRecord) throws {
        self.cloudKitID = record.recordID.recordName
        guard let recordType = record[Columns.type.name] as? String else { cloudKitLogger.error("No type"); throw PenPalError() }
        guard let recordValue = record[Columns.value.name] as? String else { cloudKitLogger.error("No value"); throw PenPalError() }
        guard let recordLastUpdated = record[Columns.lastUpdated.name] as? Date else { cloudKitLogger.error("No date"); throw PenPalError() }
        self.id = nil
        self.type = recordType
        self.value = recordValue
        self.lastUpdated = recordLastUpdated
        self.dateDeleted = record[Columns.dateDeleted.name]
    }
    
    static func create(from record: CKRecord) async throws {
        let new = try Stationery(from: record)
        try await AppDatabase.shared.save(new)
    }
    
    func update(from record: CKRecord) async throws {
        var new = try Stationery(from: record)
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
    
    var description: String { "\(self.type): \(self.value)" }
    
    static func fetchUnsynced() async -> [Stationery] {
        do {
            return try await AppDatabase.shared.fetchUnsyncedStationery()
        } catch {
            dataLogger.error("Could not fetch unsynced Stationery: \(error.localizedDescription)")
            return []
        }
    }
    
    static func fetchSynced() async -> [Stationery] {
        do {
            return try await AppDatabase.shared.fetchSyncedStationery()
        } catch {
            dataLogger.error("Could not fetch synced Stationery: \(error.localizedDescription)")
            return []
        }
    }
    
}
