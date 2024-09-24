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
        guard let parameterType = parameter.type else { return }
        let fetchRequest = NSFetchRequest<Stationery>(entityName: Stationery.entityName)
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "type = %@", parameterType.rawValue),
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
        guard let parameterType = parameter.type else { return }
        let fetchRequest = NSFetchRequest<Stationery>(entityName: Stationery.entityName)
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "type = %@", parameterType.rawValue),
            NSPredicate(format: "value = %@", parameter.name),
        ])
        do {
            for result in try context.fetch(fetchRequest) {
                dataLogger.debug("Updating \(result.wrappedValue) to \(newName)")
                result.value = newName
            }
            dataLogger.debug("Saving")
            PersistenceController.shared.save(context: context)
            Event.updateStationery(ofType: parameterType, from: parameter.name, to: newName, outbound: outbound, in: context)
        } catch {
            dataLogger.error("Could not update stationery: \(parameter): \(error.localizedDescription)")
        }        
    }
    
    @discardableResult
    static func add(type: String, value: String, to context: NSManagedObjectContext, saving: Bool = true) -> NSManagedObject {
        let stationery = Stationery(context: context)
        stationery.id = UUID()
        stationery.type = type
        stationery.value = value
        if saving {
            PersistenceController.shared.save(context: context)
        }
        return stationery
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

extension Stationery {
    static func restore(_ data: [ExportedStationery], to context: NSManagedObjectContext, saving: Bool = true) -> Int {
        let allStationery = Self.fetch(from: context).reduce(into: [String: Set<String>]()) { grouping, item in
            grouping[item.wrappedType, default: Set<String>()].insert(item.wrappedValue)
        }
        var count: Int = 0
        for importItem in data {
            if !(allStationery[importItem.type]?.contains(importItem.value) ?? false) {
                Stationery.add(type: importItem.type, value: importItem.value, to: context, saving: false)
            }
            count += 1
        }
        if saving {
            PersistenceController.shared.save(context: context)
        }
        return count
    }
}
