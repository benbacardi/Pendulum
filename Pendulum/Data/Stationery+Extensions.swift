//
//  Stationery+Extensions.swift
//  Pendulum
//
//  Created by Ben Cardy on 21/11/2022.
//

import Foundation
import CoreData

enum StationeryType: String {
    case pen
    case ink
    case paper
    
    var name: String {
        switch self {
        case .pen:
            return "Pen"
        case .ink:
            return "Ink"
        case .paper:
            return "Paper"
        }
    }
    
    var namePlural: String {
        switch self {
        case .pen:
            return "Pens"
        case .ink:
            return "Inks"
        case .paper:
            return "Paper"
        }
    }
    
    var recordType: String {
        switch self {
        case .pen:
            return "pen"
        case .ink:
            return "ink"
        case .paper:
            return "paper"
        }
    }
    
    var icon: String {
        switch self {
        case .pen:
            return "pencil"
        case .ink:
            return "drop"
        case .paper:
            return "doc.plaintext"
        }
    }
    
}

extension Stationery {
    
    static let entityName: String = "Stationery"
    
    var wrappedType: String { self.type ?? "type" }
    var wrappedValue: String { self.value ?? "value" }
    
    static func fetch(from context: NSManagedObjectContext) -> [Stationery] {
        let fetchRequest = NSFetchRequest<Stationery>(entityName: Stationery.entityName)
        do {
            return try context.fetch(fetchRequest)
        } catch {
            dataLogger.error("Could not fetch stationery: \(error.localizedDescription)")
        }
        return []
    }
    
    static func fetchUnused(for type: StationeryType, from context: NSManagedObjectContext) -> [String] {
        let fetchRequest = NSFetchRequest<Stationery>(entityName: Stationery.entityName)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "value", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "type = %@", type.rawValue)
        do {
            let results = try context.fetch(fetchRequest).map { $0.wrappedValue }
            dataLogger.debug("Results for type \(type.name): \(results)")
            return results
        } catch {
            dataLogger.error("Could not fetch unused stationery of type: \(type.rawValue): \(error.localizedDescription)")
        }
        return []
    }
    
    static func delete(_ parameter: ParameterCount, in context: NSManagedObjectContext) {
        let fetchRequest = NSFetchRequest<Stationery>(entityName: Stationery.entityName)
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "type = %@", parameter.type.rawValue),
            NSPredicate(format: "value = %@", parameter.name),
        ])
        do {
            for result in try context.fetch(fetchRequest) {
                context.delete(result)
            }
            PersistenceController.shared.save(context: context)
        } catch {
            dataLogger.error("Could not delete stationery: \(parameter)")
        }
    }
    
    func delete(in context: NSManagedObjectContext, saving: Bool = true) {
        context.delete(self)
        if saving {
            PersistenceController.shared.save(context: context)
        }
    }
    
    static func update(_ parameter: ParameterCount, to newName: String, outbound: Bool = true, in context: NSManagedObjectContext) {
        let fetchRequest = NSFetchRequest<Stationery>(entityName: Stationery.entityName)
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "type = %@", parameter.type.rawValue),
            NSPredicate(format: "value = %@", parameter.name),
        ])
        do {
            for result in try context.fetch(fetchRequest) {
                dataLogger.debug("Updating \(result.wrappedValue) to \(newName)")
                result.value = newName
            }
            dataLogger.debug("Saving")
            PersistenceController.shared.save(context: context)
            Event.updateStationery(ofType: parameter.type, from: parameter.name, to: newName, outbound: outbound, in: context)
        } catch {
            dataLogger.error("Could not update stationery: \(parameter): \(error.localizedDescription)")
        }        
    }
    
}

extension Stationery {
    static func deleteAll(in context: NSManagedObjectContext) {
        for stationery in fetch(from: context) {
            stationery.delete(in: context, saving: false)
        }
        PersistenceController.shared.save(context: context)
    }
}
