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
    
    @discardableResult
    func updateLastEvent(for penpal: PenPal, with event: Event? = nil) async throws -> EventType {
        let newEventType: Int
        let newEventDate: Date?
        if let event = event {
            newEventType = event._type
            newEventDate = event.date
        } else {
            if let fetchedEvent = await penpal.fetchLatestEvent() {
                newEventType = fetchedEvent._type
                newEventDate = fetchedEvent.date
            } else {
                newEventType = 0
                newEventDate = nil
            }
        }
        let _ = try await dbWriter.write { db in
            try PenPal.filter(Column("id") == penpal.id).updateAll(db, Column("_lastEventType").set(to: newEventType), Column("lastEventDate").set(to: newEventDate))
        }
        return EventType(rawValue: newEventType) ?? .noEvent
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
    
}
