//
//  CustomStationery+Extensions.swift
//  Pendulum
//
//  Created by Ben Cardy on 01/07/2024.
//

import Foundation
import CoreData

struct CustomStationeryType: Identifiable, Hashable {
    let id: UUID = UUID()
    let type: String
    let icon: String
    var value: String = ""
    
    static func from(_ customStationery: CustomStationery) -> CustomStationeryType {
        .init(type: customStationery.wrappedType, icon: customStationery.wrappedIcon, value: customStationery.wrappedValue)
    }
    
}

extension CustomStationery {
    
    static let entityName: String = "CustomStationery"
    
    var wrappedType: String { self.type ?? "type" }
    var wrappedValue: String { self.value ?? "value" }
    var wrappedIcon: String { self.icon ?? "icon" }
    
    var values: [String] {
        return wrappedValue.components(separatedBy: Event.optionSeparators).map { $0.trimmingCharacters(in: .whitespaces) }
    }
    
}

extension CustomStationery {
    
    static func fetchDistinctTypes(from context: NSManagedObjectContext) -> [CustomStationeryType] {
        let fetchRequest = NSFetchRequest<NSDictionary>(entityName: CustomStationery.entityName)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "type", ascending: true)]
        fetchRequest.resultType = .dictionaryResultType
        fetchRequest.propertiesToFetch = ["type", "icon"]
        fetchRequest.returnsDistinctResults = true
        do {
            let databaseResults = try context.fetch(fetchRequest) as! [[String: String]]
            return databaseResults.compactMap { result in
                guard let type = result["type"], let icon = result["icon"] else { return nil }
                return CustomStationeryType(type: type, icon: icon)
            }
        } catch {
            dataLogger.error("Could not fetch distinct custom stationery types: \(error.localizedDescription)")
        }
        return []
    }
    
    static func fetchDistinctValues(ofType type: String, from context: NSManagedObjectContext) -> [String] {
        let fetchRequest = NSFetchRequest<NSDictionary>(entityName: CustomStationery.entityName)
        fetchRequest.predicate = NSPredicate(format: "type = %@", type)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "value", ascending: true)]
        fetchRequest.resultType = .dictionaryResultType
        fetchRequest.propertiesToFetch = ["value"]
        fetchRequest.returnsDistinctResults = true
        do {
            return try context.fetch(fetchRequest).compactMap { $0["value"] as? String }
        } catch {
            dataLogger.error("Could not fetch distinct values of custom stationery type: \(error.localizedDescription)")
        }
        return []
    }
    
    /// Values that have been pre-seeded from the stationery list but aren't yet attached to any event.
    static func fetchUnassignedValues(ofType type: String, from context: NSManagedObjectContext) -> [String] {
        let fetchRequest = NSFetchRequest<CustomStationery>(entityName: CustomStationery.entityName)
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "type = %@", type),
            NSPredicate(format: "event == nil"),
            NSPredicate(format: "value != nil"),
        ])
        do {
            return try context.fetch(fetchRequest).flatMap { $0.values }.filter { !$0.isEmpty }
        } catch {
            dataLogger.error("Could not fetch unassigned custom stationery values of type \(type): \(error.localizedDescription)")
        }
        return []
    }

    static func update(_ parameter: ParameterCount, to newName: String, in context: NSManagedObjectContext) {
        guard let parameterType = parameter.customType else { return }
        let fetchRequest = NSFetchRequest<CustomStationery>(entityName: CustomStationery.entityName)
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "type = %@", parameterType.type),
            NSPredicate(format: "value = %@", parameter.name),
        ])
        do {
            for result in try context.fetch(fetchRequest) {
                dataLogger.debug("Updating \(result.wrappedValue) to \(newName)")
                result.value = newName
            }
            dataLogger.debug("Saving")
            PersistenceController.shared.save(context: context)
        } catch {
            dataLogger.error("Could not update custom stationery: \(parameter): \(error.localizedDescription)")
        }
    }
    
    static func update(_ type: CustomStationeryType, to newType: CustomStationeryType, in context: NSManagedObjectContext) {
        let fetchRequest = NSFetchRequest<CustomStationery>(entityName: CustomStationery.entityName)
        fetchRequest.predicate = NSPredicate(format: "type = %@", type.type)
        do {
            for result in try context.fetch(fetchRequest) {
                dataLogger.debug("Updating \(result.wrappedType) (\(result.wrappedIcon)) to \(newType.type) (\(newType.icon))")
                result.type = newType.type
                result.icon = newType.icon
            }
            PersistenceController.shared.save(context: context)
        } catch {
            dataLogger.error("Could not update custom stationery \(type.type): \(error.localizedDescription)")
        }
    }
    
    /// Registers a new stationery category with no values yet, so it shows up as a fillable
    /// field on future events even before it's actually been used on one.
    static func createType(_ type: CustomStationeryType, in context: NSManagedObjectContext, saving: Bool = true) {
        let newStationery = CustomStationery(context: context)
        newStationery.id = UUID()
        newStationery.type = type.type
        newStationery.icon = type.icon
        dataLogger.debug("Created CustomStationery type \(type.type) [\(type.icon)] with no value")
        if saving {
            PersistenceController.shared.save(context: context)
        }
    }

    /// Pre-seeds a value for a category without attaching it to any event, mirroring how
    /// pens/inks/papers can be added from the stationery list before ever being used. Reuses
    /// an existing empty placeholder row (see `createType`) for this type if one exists,
    /// rather than leaving it orphaned alongside a new row.
    static func addValue(_ value: String, toType type: CustomStationeryType, in context: NSManagedObjectContext, saving: Bool = true) {
        let fetchRequest = NSFetchRequest<CustomStationery>(entityName: CustomStationery.entityName)
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "type = %@", type.type),
            NSPredicate(format: "event == nil"),
            NSPredicate(format: "value == nil"),
        ])
        do {
            let placeholder = try context.fetch(fetchRequest).first
            if let placeholder {
                dataLogger.debug("Reusing placeholder CustomStationery \(type.type) for new value \(value)")
                placeholder.value = value
            } else {
                let newStationery = CustomStationery(context: context)
                newStationery.id = UUID()
                newStationery.type = type.type
                newStationery.icon = type.icon
                newStationery.value = value
                dataLogger.debug("Created unassigned CustomStationery \(type.type) [\(type.icon)] (\(value))")
            }
            if saving {
                PersistenceController.shared.save(context: context)
            }
        } catch {
            dataLogger.error("Could not add custom stationery value: \(error.localizedDescription)")
        }
    }

    static func delete(_ type: CustomStationeryType, in context: NSManagedObjectContext) {
        let fetchRequest = NSFetchRequest<CustomStationery>(entityName: CustomStationery.entityName)
        fetchRequest.predicate = NSPredicate(format: "type = %@", type.type)
        do {
            let results = try context.fetch(fetchRequest)
            for result in results {
                context.delete(result)
            }
            PersistenceController.shared.save(context: context)
        } catch {
            dataLogger.error("Could not delete custom stationery type \(type.type): \(error.localizedDescription)")
        }
    }

    /// Removes a single value from every event that references it, deleting the underlying
    /// `CustomStationery` record if that was its only value - unless doing so would leave the
    /// category with no records at all, in which case one emptied record is kept as a
    /// placeholder so the category itself stays registered (see `createType`).
    static func delete(_ parameter: ParameterCount, in context: NSManagedObjectContext) {
        guard let parameterType = parameter.customType else { return }
        let typeFetchRequest = NSFetchRequest<CustomStationery>(entityName: CustomStationery.entityName)
        typeFetchRequest.predicate = NSPredicate(format: "type = %@", parameterType.type)
        let matchFetchRequest = NSFetchRequest<CustomStationery>(entityName: CustomStationery.entityName)
        matchFetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "type = %@", parameterType.type),
            NSPredicate(format: "value CONTAINS %@", parameter.name),
        ])
        do {
            let allOfType = try context.fetch(typeFetchRequest)
            let matches = try context.fetch(matchFetchRequest)

            var toDelete: [CustomStationery] = []
            for result in matches {
                let remainingValues = result.values.filter { $0 != parameter.name }.uniqued()
                if remainingValues.isEmpty {
                    toDelete.append(result)
                } else {
                    dataLogger.debug("Removing value \(parameter.name) from CustomStationery \(result.wrappedType)")
                    result.value = remainingValues.joined(separator: "\n")
                }
            }

            if allOfType.count - toDelete.count <= 0, let placeholder = toDelete.first {
                dataLogger.debug("Keeping CustomStationery type \(placeholder.wrappedType) registered with no values")
                placeholder.event = nil
                placeholder.value = nil
                toDelete.removeFirst()
            }

            for result in toDelete {
                dataLogger.debug("Deleting CustomStationery \(result.wrappedType) [\(result.wrappedIcon)] as its only value was removed")
                context.delete(result)
            }

            PersistenceController.shared.save(context: context)
        } catch {
            dataLogger.error("Could not delete custom stationery value: \(parameter): \(error.localizedDescription)")
        }
    }

}
