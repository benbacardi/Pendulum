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
            try PenPal.fetchAll(db)
        }
    }
    
    @discardableResult func save(_ penPal: PenPal) async throws -> PenPal {
        try await dbWriter.write { db in
            try penPal.saved(db)
        }
    }
    
    @discardableResult func save(_ event: Event) async throws -> Event {
        try await dbWriter.write { db in
            try event.saved(db)
        }
    }
    
    func fetchLatestEvent(for penpal: PenPal) async throws -> Event? {
        try await dbWriter.read { db in
            try penpal.events.order(Column("date").desc).fetchOne(db)
        }
    }
    
}
