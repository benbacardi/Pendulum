//
//  PersistenceController.swift
//  Pendulum
//
//  Created by Ben Cardy on 18/11/2022.
//

import Foundation
import CoreData

struct PersistenceController {
    // A singleton for our entire app to use
    static let shared = PersistenceController()

    // Storage for Core Data
    let container: NSPersistentCloudKitContainer

    // A test configuration for SwiftUI previews
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)

        let p1 = PenPal(context: controller.container.viewContext)
        p1.id = UUID()
        p1.initials = "BC"
        p1.name = "Ben Cardy"
        p1.lastEventType = EventType.allCases.randomElement() ?? .noEvent
        
        let e1 = Event(context: controller.container.viewContext)
        e1.id = UUID()
        e1.penpal = p1
        e1.date = Date()
        e1.type = EventType.written

        return controller
    }()
    
    static let appGroupStoreURL: URL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: APP_GROUP)!.appendingPathComponent("Pendulum.sqlite")

    // An initializer to load Core Data, optionally able
    // to use an in-memory store.
    init(inMemory: Bool = false) {
        // If you didn't name your model Main you'll need
        // to change this name below.
        container = NSPersistentCloudKitContainer(name: "Pendulum")
        
        let SHOULD_MIGRATE: Bool = true

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        } else {
            if SHOULD_MIGRATE {
#if !IN_EXTENSION
                if !UserDefaults.shared.hasPerformedCoreDataMigrationToAppGroup {
                    migrateStore(for: container)
                } else {
                    container.persistentStoreDescriptions.first?.url = PersistenceController.appGroupStoreURL
                }
#else
                container.persistentStoreDescriptions.first?.url = PersistenceController.appGroupStoreURL
#endif
            }
        }
        
        //Setup auto merge of Cloudkit data
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Error: \(description): \(error.localizedDescription)")
            }
        }
        
        //Set the Query generation to .current. for dynamically updating views from Cloudkit
        try? container.viewContext.setQueryGenerationFrom(.current)
        
    }
    
    private func migrateStore(for container: NSPersistentContainer) {

        // see what configuration you're going to apply to the new store
        for persistentStoreDescription in container.persistentStoreDescriptions {
            appLogger.info("BEN: opt \(persistentStoreDescription.options)")
            appLogger.info("BEN: type \(persistentStoreDescription.type)")
            appLogger.info("BEN: conn \(persistentStoreDescription.configuration?.debugDescription ?? "")")
            appLogger.info("BEN: url \(persistentStoreDescription.url?.absoluteString ?? "")")
            
            do {
                appLogger.info("BEN: copy persistence store")
                try container.persistentStoreCoordinator.replacePersistentStore(
                    at: PersistenceController.appGroupStoreURL,  //destination
                    destinationOptions: persistentStoreDescription.options,
                    withPersistentStoreFrom: container.persistentStoreDescriptions.first!.url!, // source
                    sourceOptions: persistentStoreDescription.options,
                    ofType: persistentStoreDescription.type
                )
            } catch {
                appLogger.error("BEN: failed to copy persistence store: \(error.localizedDescription)")
            }

        }
        
        container.persistentStoreDescriptions.first!.url = PersistenceController.appGroupStoreURL

        // Used to verify the URL has changed and other config is there
        for persistentStoreDescription in container.persistentStoreDescriptions {
            appLogger.info("BEN: opt \(persistentStoreDescription.options)")
            appLogger.info("BEN: type \(persistentStoreDescription.type)")
            appLogger.info("BEN: conn \(persistentStoreDescription.configuration?.debugDescription ?? "")")
            appLogger.info("BEN: url \(persistentStoreDescription.url?.absoluteString ?? "")")
        }
        
        UserDefaults.shared.hasPerformedCoreDataMigrationToAppGroup = true
        
    }
    
    func save(context: NSManagedObjectContext) {
        if context.hasChanges {
            DispatchQueue.main.async {
                do {
                    try container.viewContext.save()
                } catch {
                    dataLogger.error("[CoreData:save] Could not save context: \(error.localizedDescription)")
                }
            }
        }
    }
    
}
