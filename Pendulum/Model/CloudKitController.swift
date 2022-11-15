//
//  CloudKitController.swift
//  Pendulum
//
//  Created by Ben Cardy on 14/11/2022.
//

import Foundation
import CloudKit

class CloudKitController {
    
    static let shared = CloudKitController()
    
    let containerIdentifier = "iCloud.uk.co.bencardy.Pendulum"
    let container: CKContainer
    
    init() {
        container = CKContainer(identifier: containerIdentifier)
    }
    
    func upload(_ penpals: [PenPal]) async {
        do {
            let new = penpals.filter { $0.cloudKitID == nil }
            let old = penpals.filter { $0.cloudKitID != nil }.map { $0.convertToCKRecord() }
            for penpal in new {
                cloudKitLogger.debug("[upload] Attempting to save \(penpal.name)")
                let uploaded = try await container.privateCloudDatabase.save(penpal.convertToCKRecord())
                await penpal.setCloudKitId(to: uploaded.recordID.recordName)
            }
            if !old.isEmpty {
                cloudKitLogger.debug("[upload] Attempting to modify \(old)")
                let _ = try await container.privateCloudDatabase.modifyRecords(saving: old, deleting: [], savePolicy: .changedKeys)
            }
        } catch {
            cloudKitLogger.error("[upload] Could not upload PenPal to CloudKit: \(error.localizedDescription)")
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
    
    func fetchAllRecords(ofType type: String) async -> [CKRecord] {
        cloudKitLogger.debug("[fetchAllRecords] Fetching all records of type \(type)")
        let predicate = NSPredicate(value: true)
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
    
    func performFullSync() async {
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
        
        var unsyncedPenPals: [PenPal] = []
        do {
            unsyncedPenPals = try await AppDatabase.shared.fetchUnsyncedPenPals()
        } catch {
            dataLogger.error("[performFullSync] Could not fetch unsycned PenPals: \(error.localizedDescription)")
            unsyncedPenPals = []
        }
        
        cloudKitLogger.debug("[performFullSync] Unsynced Pen Pals: \(unsyncedPenPals.map { $0.name })")
        
        let cloudPenPalRecords = await self.fetchAllRecords(ofType: PenPal.cloudKitRecordType)
        cloudKitLogger.debug("[performFullSync] Fetched \(cloudPenPalRecords.count) CloudKit PenPals")
        
        var syncedPenPals: [String: PenPal] = [:]
        do {
            for penpal in try await AppDatabase.shared.fetchSyncedPenPals() {
                guard let cloudKitID = penpal.cloudKitID else { continue }
                syncedPenPals[cloudKitID] = penpal
            }
        } catch {
            dataLogger.error("[performFullSync] Could not fetch synced PenPals: \(error.localizedDescription)")
        }
        
        var newLocalRecords: [CKRecord] = []
        var updateLocalRecords: [CKRecord: PenPal] = [:]
        
        for record in cloudPenPalRecords {
            if let localPenPal = syncedPenPals[record.recordID.recordName] {
                cloudKitLogger.debug("[performFullSync] Comparing \(record) to \(localPenPal.name)")
                let localLastUpdated = localPenPal.lastUpdated ?? .distantPast
                guard let cloudKitLastUpdated = record["lastUpdated"] as? Date else {
                    cloudKitLogger.warning("[performFullSync] [\(localPenPal.name)] Malformed CloudKit record, ignoring.")
                    continue
                }
                if localLastUpdated < cloudKitLastUpdated {
                    cloudKitLogger.debug("[performFullSync] [\(localPenPal.name)] CloudKit is more recent (\(cloudKitLastUpdated) vs \(localLastUpdated))")
                    updateLocalRecords[record] = localPenPal
                } else if cloudKitLastUpdated < localLastUpdated {
                    cloudKitLogger.debug("[performFullSync] [\(localPenPal.name)] Local is more recent (\(localLastUpdated) vs \(cloudKitLastUpdated))")
                    unsyncedPenPals.append(localPenPal)
                } else {
                    cloudKitLogger.debug("[performFullSync] [\(localPenPal.name)] Identical timestamps; no changes")
                }
            } else {
                cloudKitLogger.debug("[performFullSync] CloudKit record not found locally: \(record)")
                newLocalRecords.append(record)
            }
        }
        
        cloudKitLogger.debug("[performFullSync] Uploading \(unsyncedPenPals.count): \(unsyncedPenPals.map { $0.name })")
        await self.upload(unsyncedPenPals)
        
        cloudKitLogger.debug("[performFullSync] Saving \(newLocalRecords.count) locally: \(newLocalRecords)")
        for record in newLocalRecords {
            do {
                let penpal = try PenPal(from: record)
                try await AppDatabase.shared.save(penpal)
            } catch {
                cloudKitLogger.error("[performFullSync] Could not save \(record.recordID.recordName): \(error.localizedDescription)")
            }
        }
        
        cloudKitLogger.debug("[performFullSync] Updating \(updateLocalRecords.count) locally: \(updateLocalRecords)")
        for (record, penpal) in updateLocalRecords {
            do {
                let newPenpal = try PenPal(from: record, lastEventType: penpal.lastEventType, lastEventDate: penpal.lastEventDate)
                try await AppDatabase.shared.updatePenPal(penpal, from: newPenpal)
            } catch {
                cloudKitLogger.error("[performFullSync] Could not update \(record.recordID.recordName) for \(penpal.name): \(error.localizedDescription)")
            }
        }
        
    }
    
}
