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

    // An initializer to load Core Data, optionally able
    // to use an in-memory store.
    init(inMemory: Bool = false) {
        // If you didn't name your model Main you'll need
        // to change this name below.
        container = NSPersistentCloudKitContainer(name: "Pendulum")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
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
    
    func save() {
        if container.viewContext.hasChanges {
            DispatchQueue.main.async {
                do {
                    try container.viewContext.save()
                } catch {
                    dataLogger.error("[CoreData:save] Could not save context: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func export() -> Data? {
        let encoder = JSONEncoder()
        let penpals = PenPal.fetchAll()
        let stationery = Stationery.fetchAll()
        do {
            return try encoder.encode(Export(penpals: penpals, stationery: stationery))
        } catch {
            dataLogger.error("Could not generate export: \(error.localizedDescription)")
        }
        return nil
    }
    
    func exportToFile() -> URL? {
        guard let data = self.export() else { return nil }
        let documentsDirectoryURL = try! FileManager().url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let file2ShareURL = documentsDirectoryURL.appendingPathComponent("pendulum-export.json")
        do {
            try data.write(to: file2ShareURL)
            return file2ShareURL
        } catch {
            appLogger.error("Could not save export file: \(error.localizedDescription)")
        }
        return nil
    }
    
}
