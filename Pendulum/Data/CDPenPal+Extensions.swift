//
//  CDPenPal+Extensions.swift
//  Pendulum
//
//  Created by Ben Cardy on 19/11/2022.
//

import Foundation
import SwiftUI
import CoreData

extension CDPenPal {
    
    static let entityName: String = "CDPenPal"
    
    var wrappedName: String {
        self.name ?? "Unknown Pen Pal"
    }
    var wrappedInitials: String {
        self.initials ?? "UP"
    }
 
    var lastEventType: EventType {
        get { return EventType.from(self.lastEventTypeValue) }
        set { self.lastEventTypeValue = Int16(newValue.rawValue) }
    }
    
    var groupingEventType: EventType {
        self.archived ? .archived : self.lastEventType
    }
    
    var displayImage: Image? {
        if let imageData = self.image, let image = UIImage(data: imageData) {
            return Image(uiImage: image).resizable()
        }
        return nil
    }
    
}

extension CDPenPal {
    
    var ownEventsPredicate: NSPredicate {
        NSPredicate(format: "penpal = %@", self)
    }
    
    func addEvent(ofType eventType: EventType, date: Date? = Date(), notes: String? = nil, pen: String? = nil, ink: String? = nil, paper: String? = nil) {
        dataLogger.debug("Adding event of type \(eventType.rawValue) to \(self.wrappedName)")
        let context = PersistenceController.shared.container.viewContext
        let newEvent = CDEvent(context: context)
        newEvent.id = UUID()
        newEvent.date = date
        newEvent.type = eventType
        newEvent.notes = notes
        newEvent.pen = pen
        newEvent.ink = ink
        newEvent.paper = paper
        self.addToEvents(newEvent)
        self.updateLastEventType()
        do {
            try context.save()
        } catch {
            dataLogger.error("Could not create event: \(error.localizedDescription)")
        }
    }
    
    func setLastEventType(to eventType: EventType, at date: Date?, saving: Bool = false) {
        self.lastEventType = eventType
        self.lastEventDate = date
        if saving {
            do {
                try PersistenceController.shared.container.viewContext.save()
            } catch {
                dataLogger.error("Could not set last event type for \(self.wrappedName): \(error.localizedDescription)")
            }
        }
    }
    
    @discardableResult
    func updateLastEventType(saving: Bool = false) -> EventType {
        var newEventType: EventType = .noEvent
        var newEventDate: Date? = nil
        
        var updateFromDb: Bool = true
        if let lastWritten = self.getLastEvent(ofType: .written) {
            let lastSent = self.getLastEvent(ofType: .sent)
            if lastSent?.date ?? .distantPast < lastWritten.date ?? .distantPast {
                newEventType = .written
                newEventDate = lastWritten.date
                updateFromDb = false
            }
        }
        
        if updateFromDb, let lastEvent = self.getLastEvent() {
            newEventType = lastEvent.type
            newEventDate = lastEvent.date
        }
        
        dataLogger.debug("Setting the Last Event Type for \(self.wrappedName) to \(newEventType.description) at \(newEventDate?.timeIntervalSince1970 ?? 0)")
        self.setLastEventType(to: newEventType, at: newEventDate, saving: saving)
        
//        if newEventType == .received {
//            self.scheduleShouldWriteBackNotification(countingFrom: newEventDate)
//        } else {
//            self.cancelShouldWriteBackNotification()
//        }
        
        return newEventType
        
    }
    
    func getLastEvent(ofType eventType: EventType? = nil) -> CDEvent? {
        let fetchRequest = NSFetchRequest<CDEvent>(entityName: CDEvent.entityName)
        fetchRequest.fetchLimit = 1
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        if let eventType = eventType {
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                self.ownEventsPredicate,
                eventType.predicate,
            ])
        } else {
            fetchRequest.predicate = self.ownEventsPredicate
        }
        do {
            return try PersistenceController.shared.container.viewContext.fetch(fetchRequest).first
        } catch {
            dataLogger.error("Could not fetch events of type \(eventType?.description ?? "any") for \(self.wrappedName): \(error.localizedDescription)")
        }
        return nil
    }
    
    func fetchPriorEvent(to date: Date, ofType eventType: EventType) -> CDEvent? {
        let fetchRequest = NSFetchRequest<CDEvent>(entityName: CDEvent.entityName)
        fetchRequest.fetchLimit = 1
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            self.ownEventsPredicate,
            eventType.predicate,
            NSPredicate(format: "date < %@", date as NSDate)
        ])
        do {
            return try PersistenceController.shared.container.viewContext.fetch(fetchRequest).first
        } catch {
            dataLogger.error("Could not fetch prior events of type \(eventType.description) for \(self.wrappedName): \(error.localizedDescription)")
        }
        return nil
    }
    
    static func fetchDistinctStationery(ofType stationery: String, for penpal: CDPenPal? = nil) -> [ParameterCount] {
        let fetchRequest = NSFetchRequest<CDEvent>(entityName: CDEvent.entityName)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: stationery, ascending: true)]
        if let penpal = penpal {
            fetchRequest.predicate = penpal.ownEventsPredicate
        }
        do {
            let results = try PersistenceController.shared.container.viewContext.fetch(fetchRequest)
            var intermediate = Dictionary(grouping: results) {
                switch stationery {
                case "pen":
                    return $0.pen ?? ""
                case "ink":
                    return $0.ink ?? ""
                case "paper":
                    return $0.paper ?? ""
                default:
                    return ""
                }
            }.filter { $0.key != "" }.map { ParameterCount(name: $0.key, count: $0.value.count) }
            if penpal == nil {
                let unusedStationery = CDStationery.fetchUnused(for: stationery)
                let setOfResults = Set(intermediate.map { $0.name })
                for item in unusedStationery {
                    if !setOfResults.contains(item) {
                        intermediate.append(ParameterCount(name: item, count: 0))
                    }
                }
            }
            return intermediate
        } catch {
            dataLogger.error("Could not fetch distinct stationery: \(error.localizedDescription)")
        }
        return []
    }
    
    func fetchDistinctStationery(ofType stationery: String) -> [ParameterCount] {
        CDPenPal.fetchDistinctStationery(ofType: stationery, for: self)
    }
    
    func archive(_ value: Bool = true) {
        self.archived = value
        do {
            try PersistenceController.shared.container.viewContext.save()
        } catch {
            dataLogger.error("Could not archive=\(value) penpal: \(error.localizedDescription)")
        }
    }
    
    func delete() {
        PersistenceController.shared.container.viewContext.delete(self)
        do {
            try PersistenceController.shared.container.viewContext.save()
        } catch {
            dataLogger.error("Could not delete penpal: \(error.localizedDescription)")
        }
    }
    
}
