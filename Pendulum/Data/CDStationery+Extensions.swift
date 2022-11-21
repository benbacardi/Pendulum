//
//  CDStationery+Extensions.swift
//  Pendulum
//
//  Created by Ben Cardy on 21/11/2022.
//

import Foundation
import CoreData

extension CDStationery {
    
    static let entityName: String = "CDStationery"
    
    var wrappedType: String { self.type ?? "type" }
    var wrappedValue: String { self.value ?? "value" }
    
    static func fetchUnused(for type: String) -> [String] {
        let fetchRequest = NSFetchRequest<CDStationery>(entityName: CDStationery.entityName)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "value", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "type = %@", type)
        do {
            let results = try PersistenceController.shared.container.viewContext.fetch(fetchRequest)
            return results.map { $0.wrappedValue }
        } catch {
            dataLogger.error("Could not fetch unused stationery of type: \(type): \(error.localizedDescription)")
        }
        return []
    }
    
}
