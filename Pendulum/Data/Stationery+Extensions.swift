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
}

extension Stationery {
    
    static let entityName: String = "Stationery"
    
    var wrappedType: String { self.type ?? "type" }
    var wrappedValue: String { self.value ?? "value" }
    
    static func fetchAll() -> [Stationery] {
        let fetchRequest = NSFetchRequest<Stationery>(entityName: Stationery.entityName)
        do {
            return try PersistenceController.shared.container.viewContext.fetch(fetchRequest)
        } catch {
            dataLogger.error("Could not fetch all Stationery: \(error.localizedDescription)")
        }
        return []
    }
    
    static func fetchUnused(for type: StationeryType) -> [String] {
        let fetchRequest = NSFetchRequest<Stationery>(entityName: Stationery.entityName)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "value", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "type = %@", type.rawValue)
        do {
            let results = try PersistenceController.shared.container.viewContext.fetch(fetchRequest)
            return results.map { $0.wrappedValue }
        } catch {
            dataLogger.error("Could not fetch unused stationery of type: \(type.rawValue): \(error.localizedDescription)")
        }
        return []
    }
    
}
