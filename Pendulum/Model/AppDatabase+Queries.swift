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
            try PenPal.order(Column("lastEventDate").asc).fetchAll(db)
        }
    }
    
    func fetchPenPals(withStatus eventType: EventType) async throws -> [PenPal] {
        try await dbWriter.read { db in
            try PenPal.filter(Column("_lastEventType") == eventType.rawValue).fetchAll(db)
        }
    }
    
    func fetchPenPal(withId id: String) async throws -> PenPal? {
        try await dbWriter.read { db in
            try PenPal.filter(Column("id") == id).fetchOne(db)
        }
    }
    
    @discardableResult
    func save(_ penPal: PenPal) async throws -> PenPal {
        try await dbWriter.write { db in
            try penPal.saved(db)
        }
    }
    
    @discardableResult
    func save(_ event: Event) async throws -> Event {
        try await dbWriter.write { db in
            try event.saved(db)
        }
    }
    
    func getLastEvent(ofType eventType: EventType, for penpal: PenPal) async throws -> Event? {
        try await dbWriter.read { db in
            try penpal.events.filter(Column("_type") == eventType.rawValue).order(Column("date").desc).fetchOne(db)
        }
    }
    
    @discardableResult
    func setLastEventType(for penpal: PenPal, to eventType: EventType, at date: Date?) async throws -> Int {
        try await dbWriter.write { db in
            try PenPal.filter(Column("id") == penpal.id).updateAll(db, Column("_lastEventType").set(to: eventType.rawValue), Column("lastEventDate").set(to: date))
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
        return newEventType
        
    }
    
    @discardableResult
    func updatePenPal(_ existing: PenPal, from new: PenPal) async throws -> Bool {
        try await dbWriter.write { db in
            try new.updateChanges(db, from: existing)
        }
    }
    
    @discardableResult
    func updateEvent(_ existing: Event, from new: Event) async throws -> Bool {
        try await dbWriter.write { db in
            try new.updateChanges(db, from: existing)
        }
    }
    
    func fetchLatestEvent(for penpal: PenPal) async throws -> Event? {
        try await dbWriter.read { db in
            try penpal.events.order(Column("date").desc).fetchOne(db)
        }
    }
    
    func fetchAllEvents(for penpal: PenPal) async throws -> [Event] {
        try await dbWriter.read { db in
            try penpal.events.order(Column("date").desc).fetchAll(db)
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
    
    private func fetchDistinctEventNote(for column: String) async -> [String] {
        do {
            return try await dbWriter.read { db in
                try Event.select(Column(column), as: String?.self).order(Column(column)).distinct().fetchAll(db)
            }.compactMap { $0 }
        } catch {
            dataLogger.error("Could not fetch distinct \(column)s: \(error.localizedDescription)")
            return []
        }
    }
    
    func fetchDistinctPens() async -> [String] {
        return await self.fetchDistinctEventNote(for: "pen")
    }
    
    func fetchDistinctInks() async -> [String] {
        return await self.fetchDistinctEventNote(for: "ink")
    }
    
    func fetchDistinctPapers() async -> [String] {
        return await self.fetchDistinctEventNote(for: "paper")
    }
    
    private func fetchDistinctEventNote(for column: String, by penpal: PenPal?) async -> [ParameterCount] {
        
        let request: QueryInterfaceRequest<Event>
        if let penpal = penpal {
            request = penpal.events
        } else {
            request = Event.all()
        }
        
        do {
            return try await dbWriter.read { db in
                try request.select(Column(column).forKey("name"), count(Column(column)).forKey("count"), as: OptionalParameterCountRow.self).filter(Column(column) != nil).group(Column(column)).fetchAll(db)
            }.filter { $0.name != nil }.map {
                ParameterCount(name: $0.name ?? "UNKNOWN", count: $0.count)
            }
        } catch {
            dataLogger.error("Could not fetch distinct \(column)s for \(penpal?.name ?? "all"): \(error.localizedDescription)")
            return []
        }
    }
    
    func fetchDistinctPens(for penpal: PenPal?) async -> [ParameterCount] {
        return await self.fetchDistinctEventNote(for: "pen", by: penpal)
    }
    
    func fetchDistinctInks(for penpal: PenPal?) async -> [ParameterCount] {
        return await self.fetchDistinctEventNote(for: "ink", by: penpal)
    }
    
    func fetchDistinctPapers(for penpal: PenPal?) async -> [ParameterCount] {
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
