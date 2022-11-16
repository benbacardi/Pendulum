//
//  AppDatabase.swift
//  Pendulum
//
//  Created by Ben Cardy on 04/11/2022.
//

import Foundation
import GRDB

final class AppDatabase {
    
    init(_ dbWriter: DatabaseWriter) throws {
        self.dbWriter = dbWriter
        try migrator.migrate(dbWriter)
    }
    
    /// Provides access to the database.
    /// Could be `DatabasePool` or `DatabaseQueue`.
    /// See https://github.com/groue/GRDB.swift/blob/master/README.md#database-connections
    let dbWriter: DatabaseWriter
    
    /// Defines the database migrations.
    /// See https://github.com/groue/GRDB.swift/blob/master/Documentation/Migrations.md
    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        
        #if DEBUG
        /// Speed up development by nuking the database when migrations change
        /// See https://github.com/groue/GRDB.swift/blob/master/Documentation/Migrations.md#the-erasedatabaseonschemachange-option
        migrator.eraseDatabaseOnSchemaChange = true
        #endif
        
        /// Create migrations here
        migrator.registerMigration("createInitialTables") { db in
            try db.create(table: "penpal") { table in
                table.column("id", .text).primaryKey()
                table.column("contactID", .text)
                table.column("name", .text)
                table.column("initials", .text)
                table.column("image", .blob)
                table.column("_lastEventType", .integer)
                table.column("lastEventDate", .date)
                table.column("notes", .text)
                table.column("archived", .boolean).defaults(to: false)
            }
        }
        
        migrator.registerMigration("createEventTables") { db in
            try db.create(table: "event") { table in
                table.column("id", .text).primaryKey()
                table.column("penpalId", .text).notNull().references("penpal", onDelete: .cascade)
                table.column("_type", .integer).notNull()
                table.column("date", .datetime).notNull()
                table.column("notes", .text)
                table.column("pen", .text)
                table.column("ink", .text)
                table.column("paper", .text)
            }
        }
        
        migrator.registerMigration("addUnusedStationery") { db in
            try db.create(table: "stationery") { table in
                table.autoIncrementedPrimaryKey("id")
                table.column("type", .text).notNull()
                table.column("value", .text).notNull()
            }
        }
        
        migrator.registerMigration("sync") { db in
            try db.alter(table: "penpal") { table in
                table.add(column: "lastUpdated", .datetime)
                table.add(column: "dateDeleted", .datetime)
                table.add(column: "cloudKitID", .text)
            }
            try db.alter(table: "event") { table in
                table.add(column: "lastUpdated", .datetime)
                table.add(column: "dateDeleted", .datetime)
                table.add(column: "cloudKitID", .text)
            }
            try db.alter(table: "stationery") { table in
                table.add(column: "lastUpdated", .datetime)
                table.add(column: "dateDeleted", .datetime)
                table.add(column: "cloudKitID", .text)
            }
        }
        
        return migrator
    }
    
}

// MARK: Persistence

extension AppDatabase {
    
    /// The application's database
    static let shared = makeSharedDatabase()
    
    private static func makeSharedDatabase() -> AppDatabase {
        do {
            /// Create a folder in the shared container for storing the database
            let fileManager = FileManager()
            guard let folderURL = fileManager
                .containerURL(forSecurityApplicationGroupIdentifier: APP_GROUP)?
                .appendingPathComponent("database", isDirectory: true) else {
                fatalError("Unable to get container for \(APP_GROUP)")
            }
            try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true)
            
            /// Connect to a database on disk
            /// See https://github.com/groue/GRDB.swift/blob/master/README.md#database-connections
            let dbURL = folderURL.appendingPathComponent("db1.sqlite")
            var config = Configuration()
            #if DEBUG
            config.publicStatementArguments = true
            #endif
            
            config.prepareDatabase { db in
                db.trace { event in
                    #if DEBUG
                    sqlLogger.trace("\(event)")
                    #endif
                    if case let .profile(statement, duration) = event, duration > 0.5 {
                        sqlLogger.warning("Slow query: \(statement.sql)")
                    }
                }
            }
            
            do {
                let dbPool = try DatabasePool(path: dbURL.path, configuration: config)
                do {
                    return try AppDatabase(dbPool)
                } catch {
                    fatalError("Unable to initialise AppDatabase: \(error.localizedDescription)")
                }
            } catch {
                fatalError("Unable to create database pool: \(error.localizedDescription)")
            }
            
        } catch {
            fatalError("Unable to create directory for database: \(error.localizedDescription)")
        }
    }
    
}

extension AppDatabase {
    
    func observePenPalObservation() -> ValueObservation<ValueReducers.Fetch<[PenPal]>> {
        ValueObservation.tracking(PenPal.fetchAll)
    }
    
    func observeEventObservation() -> ValueObservation<ValueReducers.Fetch<[Event]>> {
        ValueObservation.tracking(Event.fetchAll)
    }
    
    func observeEventObservation(for penpal: PenPal) -> ValueObservation<ValueReducers.Fetch<[Event]>> {
        ValueObservation.tracking(penpal.events.fetchAll)
    }
    
    func start<T: ValueReducer>(observation: ValueObservation<T>,
                                scheduling scheduler: ValueObservationScheduler = .async(onQueue: .main),
                                onError: @escaping (Error) -> Void,
                                onChange: @escaping (T.Value) -> Void) -> DatabaseCancellable {
        observation.start(in: dbWriter, scheduling: scheduler, onError: onError, onChange: onChange)
    }
}
