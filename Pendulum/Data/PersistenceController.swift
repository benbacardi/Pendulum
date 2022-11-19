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

        // Create 10 example programming languages.
        for i in 0..<10 {
            let p1 = CDPenPal(context: controller.container.viewContext)
            p1.id = UUID()
            p1.initials = "B\(i)"
            p1.name = "Ben Cardy \(i)"
            p1.lastEventTypeValue = Int16(EventType.allCases.randomElement()?.rawValue ?? 0)
        }

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
