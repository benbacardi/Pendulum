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
    
}
