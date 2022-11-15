//
//  AppDatabase+Queries.swift
//  Pendulum
//
//  Created by Ben Cardy on 04/11/2022.
//

import Foundation
import GRDB

extension AppDatabase {
    
    func fetchAllPenPals() async throws -> [PenPal] {
        try await dbWriter.read { db in
            try PenPal.order(PenPal.Columns.lastEventDate.asc).fetchAll(db)
        }
    }
    
    func fetchPenPals(withStatus eventType: EventType) async throws -> [PenPal] {
        try await dbWriter.read { db in
            try PenPal.filter(PenPal.Columns._lastEventType == eventType.rawValue).fetchAll(db)
        }
    }
    
    func fetchPenPal(withId id: String) async throws -> PenPal? {
        try await dbWriter.read { db in
            try PenPal.filter(PenPal.Columns.id == id).fetchOne(db)
        }
    }
    
    @discardableResult
    func save<T: MutablePersistableRecord>(_ record: T) async throws -> T {
        try await dbWriter.write { db in
            try record.saved(db)
        }
    }
    
    func getLastEvent(ofType eventType: EventType, for penpal: PenPal) async throws -> Event? {
        try await dbWriter.read { db in
            try penpal.events.filter(Event.Columns._type == eventType.rawValue).order(Event.Columns.date.desc).fetchOne(db)
        }
    }
    
    @discardableResult
    func setLastEventType(for penpal: PenPal, to eventType: EventType, at date: Date?) async throws -> Int {
        try await dbWriter.write { db in
            try PenPal.filter(PenPal.Columns.id == penpal.id).updateAll(db, PenPal.Columns._lastEventType.set(to: eventType.rawValue), PenPal.Columns.lastEventDate.set(to: date))
        }
    }
    
    @discardableResult
    func updateLastEventType(for penpal: PenPal) async throws -> EventType {
        
        var newEventType: EventType = .noEvent
        var newEventDate: Date? = nil
        
        var readFromDb: Bool = true
        
        if let lastWritten = try await self.getLastEvent(ofType: .written, for: penpal) {
            let lastSent = try await self.getLastEvent(ofType: .sent, for: penpal)
            if lastSent?.date ?? Date.distantPast < lastWritten.date {
                newEventType = .written
                newEventDate = lastWritten.date
                readFromDb = false
            }
        }
        if readFromDb, let fetchedEvent = await penpal.fetchLatestEvent() {
                newEventType = fetchedEvent.eventType
                newEventDate = fetchedEvent.date
        }
        
        dataLogger.debug("Setting the Last Event Type for \(penpal.name) to \(newEventType.description) at \(newEventDate?.timeIntervalSince1970 ?? 0)")
        try await self.setLastEventType(for: penpal, to: newEventType, at: newEventDate)
        
        if newEventType == .received {
            /// Schedule notification
            penpal.scheduleShouldWriteBackNotification(countingFrom: newEventDate)
        } else {
            /// Cancel notification
            penpal.cancelShouldWriteBackNotification()
        }
        
        return newEventType
        
    }
    
    @discardableResult
    func update<T: MutablePersistableRecord>(_ existing: T, from new: T) async throws -> Bool {
        try await dbWriter.write { db in
            try new.updateChanges(db, from: existing)
        }
    }
    
    func fetchLatestEvent(for penpal: PenPal) async throws -> Event? {
        try await dbWriter.read { db in
            try penpal.events.order(Event.Columns.date.desc).fetchOne(db)
        }
    }
    
    func fetchAllEvents(for penpal: PenPal) async throws -> [Event] {
        try await dbWriter.read { db in
            try penpal.events.order(Event.Columns.date.desc).fetchAll(db)
        }
    }
    
    func fetchPriorEvent(to date: Date, ofType eventType: EventType, for penpal: PenPal) async throws -> Event? {
        try await dbWriter.read { db in
            try penpal.events.filter(Event.Columns._type == eventType.rawValue).filter(Event.Columns.date < date).order(Event.Columns.date.desc).fetchOne(db)
        }
    }
    
    @discardableResult
    func delete(_ penpal: PenPal) async throws -> Bool {
        try await dbWriter.write { db in
            try penpal.delete(db)
        }
    }
    
    @discardableResult
    func delete(_ event: Event) async throws -> Bool {
        try await dbWriter.write { db in
            try event.delete(db)
        }
    }
    
    func penPalFor(event: Event) async throws -> PenPal? {
        try await dbWriter.read { db in
            try event.penpal.fetchOne(db)
        }
    }
    
    func calculateBadgeNumber(toWrite: Bool, toPost: Bool) async -> Int {
        do {
            var count = 0
            if toWrite {
                count += try await self.fetchPenPals(withStatus: .received).count
            }
            if toPost {
                count += try await self.fetchPenPals(withStatus: .written).count
            }
            return count
        } catch {
            dataLogger.error("Could not calculate badge number: \(error.localizedDescription)")
            return 0
        }
    }
    
    private func fetchDistinctEventNote(for column: String, by penpal: PenPal? = nil) async -> [ParameterCount] {
        
        let request: QueryInterfaceRequest<Event>
        if let penpal = penpal {
            request = penpal.events
        } else {
            request = Event.all()
        }
        
        do {
            var results = try await dbWriter.read { db in
                try request.select(Column(column).forKey("name"), count(Column(column)).forKey("count"), as: OptionalParameterCountRow.self).filter(Column(column) != nil).group(Column(column)).order(Column("count").desc).fetchAll(db)
            }.filter { $0.name != nil }.map {
                ParameterCount(name: $0.name ?? "UNKNOWN", count: $0.count)
            }
            if penpal == nil {
                let unusedStationery = Set(await fetchUnusedStationery(for: column))
                let setOfResults = Set(results.map { $0.name })
                for diff in unusedStationery.subtracting(setOfResults) {
                    results.append(ParameterCount(name: diff, count: 0))
                }
            }
            return results
        } catch {
            dataLogger.error("Could not fetch distinct \(column)s for \(penpal?.name ?? "all"): \(error.localizedDescription)")
            return []
        }
    }
    
    private func fetchUnusedStationery(for type: String) async -> [String] {
        do {
            return try await dbWriter.read { db in
                try Stationery.select(Stationery.Columns.value).filter(Stationery.Columns.type == type).fetchAll(db)
            }
        } catch {
            dataLogger.error("Could not fetch unused stationery for \(type): \(error.localizedDescription)")
            return []
        }
    }
    
    func fetchDistinctPens(for penpal: PenPal? = nil) async -> [ParameterCount] {
        return await self.fetchDistinctEventNote(for: "pen", by: penpal)
    }
    
    func fetchDistinctInks(for penpal: PenPal? = nil) async -> [ParameterCount] {
        return await self.fetchDistinctEventNote(for: "ink", by: penpal)
    }
    
    func fetchDistinctPapers(for penpal: PenPal? = nil) async -> [ParameterCount] {
        return await self.fetchDistinctEventNote(for: "paper", by: penpal)
    }
    
    func test() async {
        do {
            let results = try await dbWriter.read { db in
                try Event.select(Column("pen").forKey("name"), count(Column("id")).forKey("count"), as: OptionalParameterCountRow.self).filter(Column("pen") != nil).group(Column("pen")).fetchAll(db)
                    .filter { $0.name != nil }
            }
            dataLogger.debug("Results: \(results)")
        } catch {
            dataLogger.error("Could not run test: \(error.localizedDescription)")
        }
    }
    
}

struct OptionalParameterCountRow: FetchableRecord, Decodable {
    var name: String?
    var count: Int
}

struct ParameterCount {
    let name: String
    let count: Int
}

extension AppDatabase {
    
    @discardableResult
    func setCloudKitId(for penpal: PenPal, to cloudKitID: String) async throws -> Int {
        try await dbWriter.write { db in
            try PenPal.filter(PenPal.Columns.id == penpal.id).updateAll(db, PenPal.Columns.cloudKitID.set(to: cloudKitID))
        }
    }
    
    @discardableResult
    func setCloudKitId(for stationery: Stationery, to cloudKitID: String) async throws -> Int {
        try await dbWriter.write { db in
            try Stationery.filter(Stationery.Columns.id == stationery.id).updateAll(db, Stationery.Columns.cloudKitID.set(to: cloudKitID))
        }
    }
    
    @discardableResult
    func setCloudKitId(for event: Event, to cloudKitID: String) async throws -> Int {
        try await dbWriter.write { db in
            try Event.filter(Event.Columns.id == event.id).updateAll(db, Event.Columns.cloudKitID.set(to: cloudKitID))
        }
    }
    
    func fetchUnsyncedPenPals() async throws -> [PenPal] {
        try await dbWriter.read { db in
            try PenPal.filter(PenPal.Columns.cloudKitID == nil).fetchAll(db)
        }
    }
    
    func fetchSyncedPenPals() async throws -> [PenPal] {
        try await dbWriter.read { db in
            try PenPal.filter(PenPal.Columns.cloudKitID != nil).fetchAll(db)
        }
    }
    
    func fetchUnsyncedStationery() async throws -> [Stationery] {
        try await dbWriter.read { db in
            try Stationery.filter(Stationery.Columns.cloudKitID == nil).fetchAll(db)
        }
    }
    
    func fetchSyncedStationery() async throws -> [Stationery] {
        try await dbWriter.read { db in
            try Stationery.filter(Stationery.Columns.cloudKitID != nil).fetchAll(db)
        }
    }
    
    func fetchUnsyncedEvents() async throws -> [Event] {
        try await dbWriter.read { db in
            try Event.filter(Event.Columns.cloudKitID == nil).fetchAll(db)
        }
    }
    
    func fetchSyncedEvents() async throws -> [Event] {
        try await dbWriter.read { db in
            try Event.filter(Event.Columns.cloudKitID != nil).fetchAll(db)
        }
    }
    
}
