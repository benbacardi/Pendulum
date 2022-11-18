//
//  CloudKitController.swift
//  Pendulum
//
//  Created by Ben Cardy on 14/11/2022.
//

import Foundation
import CloudKit
import NotificationCenter

let SyncRequiredNotification = Notification.Name("syncRequired")

protocol CloudKitSyncedModel {
    
    static var cloudKitRecordType: String { get }
    
    var cloudKitID: String? { get }
    var lastUpdated: Date? { get }
    var description: String { get }
    
    func convertToCKRecord() -> CKRecord
    func setCloudKitID(to cloudKitID: String) async
    
    init(from record: CKRecord) throws
    
    static func fetchUnsynced() async -> [Self]
    static func fetchSynced() async -> [Self]
    static func deleteRecords(notMatchingCloudKitIDs: [CKRecord]) async -> Int
    
    static func create(from record: CKRecord) async throws
    func update(from record: CKRecord) async throws
    
}

class CloudKitController {
    
    static let shared = CloudKitController()
    
    let containerIdentifier = "iCloud.uk.co.bencardy.Pendulum"
    let container: CKContainer
    
    init() {
        container = CKContainer(identifier: containerIdentifier)
    }
    
    static func triggerSyncRequiredNotification() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: SyncRequiredNotification, object: nil)
        }
    }
    
    func subscribeToChanges() async {
        let recordTypes = [
            PenPal.cloudKitRecordType,
            Event.cloudKitRecordType,
            Stationery.cloudKitRecordType,
        ]
        for recordType in recordTypes {
            let sub = CKQuerySubscription(recordType: recordType, predicate: NSPredicate(value: true), options: [.firesOnRecordCreation, .firesOnRecordUpdate])
            let notification = CKSubscription.NotificationInfo()
            notification.shouldSendContentAvailable = true
            sub.notificationInfo = notification
            do {
                let savedSub = try await self.container.privateCloudDatabase.save(sub)
                cloudKitLogger.info("Subscription created: \(savedSub)")
            } catch {
                cloudKitLogger.error("Error saving subscription for changes: \(error.localizedDescription)")
            }
        }
    }
    
    func upload(_ models: [any CloudKitSyncedModel]) async {
        do {
            let new = models.filter { $0.cloudKitID == nil }
            let old = models.filter { $0.cloudKitID != nil }.map { $0.convertToCKRecord() }
            for model in new {
                cloudKitLogger.debug("[upload] Attempting to save \(model.description)")
                let uploaded = try await container.privateCloudDatabase.save(model.convertToCKRecord())
                await model.setCloudKitID(to: uploaded.recordID.recordName)
            }
            if !old.isEmpty {
                cloudKitLogger.debug("[upload] Attempting to modify \(old)")
                let _ = try await container.privateCloudDatabase.modifyRecords(saving: old, deleting: [], savePolicy: .changedKeys)
            }
        } catch {
            cloudKitLogger.error("[upload] Could not upload Model to CloudKit: \(error.localizedDescription)")
        }
    }
    
    private func convertFetchResultsToCKRecords(for results: [(CKRecord.ID, Result<CKRecord, Error>)]) -> [CKRecord] {
        var records: [CKRecord] = []
        for result in results {
            do {
                records.append(try result.1.get())
            } catch {
                cloudKitLogger.debug("[convertFetchResultsToCKRecords] Could not convert single result: \(error.localizedDescription)")
            }
        }
        return records
    }
    
    func fetchAllRecords(ofType type: String, since: Date) async -> [CKRecord] {
        cloudKitLogger.debug("[fetchAllRecords] Fetching all records of type \(type) since \(since)")
        let predicate = NSPredicate(format: "lastUpdated >= %@", since as NSDate)
        let query = CKQuery(recordType: type, predicate: predicate)
        do {
            let results = try await self.container.privateCloudDatabase.records(matching: query, resultsLimit: 100)
            cloudKitLogger.debug("[fetchAllRecords] Fetched \(results.matchResults.count) results")
            var records: [CKRecord] = self.convertFetchResultsToCKRecords(for: results.matchResults)
            var cursor = results.queryCursor
            while let nextCursor = cursor {
                cloudKitLogger.debug("[fetchAllRecords] Fetching next set of results of type \(type)")
                let nextResults = try await self.container.privateCloudDatabase.records(continuingMatchFrom: nextCursor, resultsLimit: 100)
                cursor = nextResults.queryCursor
                cloudKitLogger.debug("[fetchAllRecords] Fetched \(nextResults.matchResults.count) more records of type \(type)")
                records += self.convertFetchResultsToCKRecords(for: nextResults.matchResults)
            }
            return records
        } catch {
            cloudKitLogger.debug("[fetchAllRecords] Could not fetch records of type \(type): \(error.localizedDescription)")
        }
        return []
    }
    
    func performSync<Model: CloudKitSyncedModel>(for _: Model.Type) async -> Bool {
        /// Sync the local GRDB database with CloudKit.
        ///
        /// Syncing process:
        ///  - All synced models should have the fields `lastUpdated`, `dateDeleted`, and `cloudKitRecordID`
        ///  - Any model objects without a `cloudKitRecordID` are new and will be uploaded to CloudKit, storing the returned record ID for later use.
        ///  - CloudKit records with a more recent `lastUpdated` will be used to update the local GRDB model.
        ///  - CloudKit records with an older `lastUpdated` will be updated from the data in the local GRDB model.
        ///
        /// Things to be aware of:
        ///  - All changes to the models need to set the `lastUpdated` field to the date of the change.
        ///  - Updating the `lastUpdated` and `cloudKitRecordID` fields should *not* trigger anything that updates the `lastUpdated` field.
        ///  - Deleting model means setting `dateDeleted` instead of actually removing it. This should be treated like any other field as far as updates and
        ///    between CloudKit and GRDB are concerned.
        let logPrefix = "[performSync:\(Model.cloudKitRecordType)]"
        
        let modifiedSince: Date = .distantPast
        var syncSuccess = true
        
        var unsynced = await Model.fetchUnsynced()
        cloudKitLogger.debug("\(logPrefix) Unsynced: \(unsynced.count)")
        
        let cloudKitRecords = await self.fetchAllRecords(ofType: Model.cloudKitRecordType, since: modifiedSince)
        cloudKitLogger.debug("\(logPrefix) From CloudKit: \(cloudKitRecords.count)")
        
        var synced: [String: Model] = [:]
        for syncedModel in await Model.fetchSynced() {
            guard let cloudKitID = syncedModel.cloudKitID else { continue }
            synced[cloudKitID] = syncedModel
        }
        
        var newLocalRecords: [CKRecord] = []
        var updateLocalRecords: [CKRecord: Model] = [:]
        
        for record in cloudKitRecords {
            if let localModel = synced[record.recordID.recordName] {
                cloudKitLogger.debug("\(logPrefix) Comparing \(record) to \(localModel.description)")
                let localLastUpdated = localModel.lastUpdated ?? .distantPast
                guard let cloudKitLastUpdated = record["lastUpdated"] as? Date else {
                    cloudKitLogger.warning("\(logPrefix) [\(localModel.description)] Malformed CloudKit record, ignoring.")
                    continue
                }
                if localLastUpdated < cloudKitLastUpdated {
                    cloudKitLogger.debug("\(logPrefix) [\(localModel.description)] CloudKit is more recent (\(cloudKitLastUpdated) vs \(localLastUpdated))")
                    updateLocalRecords[record] = localModel
                } else if cloudKitLastUpdated < localLastUpdated {
                    cloudKitLogger.debug("\(logPrefix) [\(localModel.description)] Local is more recent (\(localLastUpdated) vs \(cloudKitLastUpdated))")
                    unsynced.append(localModel)
                } else {
                    cloudKitLogger.debug("\(logPrefix) [\(localModel.description)] Identical timestamps; no changes")
                }
            } else {
                cloudKitLogger.debug("\(logPrefix) CloudKit record not found locally: \(record)")
                if let cloudKitDateDeleted = record["dateDeleted"] as? Date {
                    cloudKitLogger.debug("\(logPrefix) Not saving locally, as deleted on \(cloudKitDateDeleted)")
                } else {
                    newLocalRecords.append(record)
                }
            }
        }
        
        cloudKitLogger.debug("\(logPrefix) Uploading \(unsynced.count): \(unsynced.map { $0.description })")
        await self.upload(unsynced)
        
        cloudKitLogger.debug("\(logPrefix) Saving \(newLocalRecords.count) locally: \(newLocalRecords)")
        for record in newLocalRecords {
            do {
                try await Model.create(from: record)
            } catch {
                cloudKitLogger.error("\(logPrefix) Could not save \(record.recordID.recordName): \(error.localizedDescription)")
                syncSuccess = false
            }
        }
        
        cloudKitLogger.debug("\(logPrefix) Updating \(updateLocalRecords.count) locally: \(updateLocalRecords)")
        for (record, obj) in updateLocalRecords {
            do {
                try await obj.update(from: record)
            } catch {
                cloudKitLogger.error("[performFullSync] Could not update \(record.recordID.recordName) for \(obj.description): \(error.localizedDescription)")
                syncSuccess = false
            }
        }
        
        cloudKitLogger.debug("\(logPrefix) Deleting old records not matching CloudKit IDs...")
        let numDeleted = await Model.deleteRecords(notMatchingCloudKitIDs: cloudKitRecords)
        cloudKitLogger.debug("\(logPrefix) Deleted \(numDeleted) records")
        
        return syncSuccess
        
    }
    
    @discardableResult
    func performFullSync() async -> Bool {
        let penpalSuccess = await self.performSync(for: PenPal.self)
        let stationerySuccess = await self.performSync(for: Stationery.self)
        let eventSuccess = await self.performSync(for: Event.self)
        let syncSuccess = penpalSuccess && stationerySuccess && eventSuccess
        return syncSuccess
    }
    
    func deleteAll() async {
        var penpalRecords = await self.fetchAllRecords(ofType: PenPal.cloudKitRecordType, since: .distantPast)
        var eventRecords = await self.fetchAllRecords(ofType: Event.cloudKitRecordType, since: .distantPast)
        var stationeryRecords = await self.fetchAllRecords(ofType: Stationery.cloudKitRecordType, since: .distantPast)
        let recordIdsToDelete = (penpalRecords + eventRecords + stationeryRecords).map { $0.recordID }
        cloudKitLogger.info("[deleteAll] Deleting \(recordIdsToDelete.count) records")
        var count = 1
        for chunk in recordIdsToDelete.chunked(into: 100) {
            cloudKitLogger.info("[deleteAll] Deleting \(count): \(chunk.count)")
            do {
                try await container.publicCloudDatabase.modifyRecords(saving: [], deleting: chunk)
            } catch {
                cloudKitLogger.error("[deleteAll] Could not delete records: \(error.localizedDescription)")
            }
            count += 1
        }
    }
    
}
