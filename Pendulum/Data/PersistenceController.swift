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
    let container: NSPersistentContainer

    // A test configuration for SwiftUI previews
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)

        let p1 = CDPenPal(context: controller.container.viewContext)
        p1.id = UUID()
        p1.initials = "BC"
        p1.name = "Ben Cardy"
        p1.lastEventType = EventType.allCases.randomElement() ?? .noEvent
        
        let e1 = CDEvent(context: controller.container.viewContext)
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
        container = NSPersistentContainer(name: "Pendulum")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Error: \(error.localizedDescription)")
            }
        }
    }
    
    func save() {
        let context = container.viewContext

        if context.hasChanges {
            do {
                try context.save()
            } catch {
                dataLogger.error("[CoreData:save] Could not save context: \(error.localizedDescription)")
            }
        }
    }
    
}
