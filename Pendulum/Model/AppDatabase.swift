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
                table.column("givenName", .text)
                table.column("familyName", .text)
                table.column("image", .blob)
            }
        }
        
        migrator.registerMigration("createEventTables") { db in
            try db.create(table: "event") { table in
                table.autoIncrementedPrimaryKey("id")
                table.column("penpalId", .text).notNull().references("penpal")
                table.column("type", .integer).notNull()
                table.column("date", .datetime).notNull()
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
            let dbURL = folderURL.appendingPathComponent("db.sqlite")
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
    
    func start<T: ValueReducer>(observation: ValueObservation<T>,
                                scheduling scheduler: ValueObservationScheduler = .async(onQueue: .main),
                                onError: @escaping (Error) -> Void,
                                onChange: @escaping (T.Value) -> Void) -> DatabaseCancellable {
        observation.start(in: dbWriter, scheduling: scheduler, onError: onError, onChange: onChange)
    }
}
