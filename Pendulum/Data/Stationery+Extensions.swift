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
