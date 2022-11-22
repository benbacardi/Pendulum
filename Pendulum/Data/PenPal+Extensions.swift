//
//  PenPal+Extensions.swift
//  Pendulum
//
//  Created by Ben Cardy on 19/11/2022.
//

import Foundation
import SwiftUI
import CoreData
import Contacts

extension PenPal {
    
    static let entityName: String = "PenPal"
    
    var wrappedName: String {
        self.name ?? "Unknown Pen Pal"
    }
    var wrappedInitials: String {
        self.initials ?? "?"
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

extension PenPal {
    
    var ownEventsPredicate: NSPredicate {
        NSPredicate(format: "penpal = %@", self)
    }
    
    func addEvent(ofType eventType: EventType, date: Date? = Date(), notes: String? = nil, pen: String? = nil, ink: String? = nil, paper: String? = nil) {
        dataLogger.debug("Adding event of type \(eventType.rawValue) to \(self.wrappedName)")
        let newEvent = Event(context: PersistenceController.shared.container.viewContext)
        newEvent.id = UUID()
        newEvent.date = date
        newEvent.type = eventType
        newEvent.notes = notes
        newEvent.pen = pen
        newEvent.ink = ink
        newEvent.paper = paper
        self.addToEvents(newEvent)
        self.updateLastEventType()
        PersistenceController.shared.save()
    }
    
    func setLastEventType(to eventType: EventType, at date: Date?, saving: Bool = false) {
        self.lastEventType = eventType
        self.lastEventDate = date
        if saving {
            PersistenceController.shared.save()
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
        
        if newEventType == .received {
            self.scheduleShouldWriteBackNotification(countingFrom: newEventDate)
        } else {
            self.cancelShouldWriteBackNotification()
        }
        
        return newEventType
        
    }
    
    func getLastEvent(ofType eventType: EventType? = nil) -> Event? {
        let fetchRequest = NSFetchRequest<Event>(entityName: Event.entityName)
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
    
    func fetchPriorEvent(to date: Date, ofType eventType: EventType) -> Event? {
        let fetchRequest = NSFetchRequest<Event>(entityName: Event.entityName)
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
    
    static func fetchDistinctStationery(ofType stationery: StationeryType, for penpal: PenPal? = nil) -> [ParameterCount] {
        let fetchRequest = NSFetchRequest<Event>(entityName: Event.entityName)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: stationery.rawValue, ascending: true)]
        if let penpal = penpal {
            fetchRequest.predicate = penpal.ownEventsPredicate
        }
        do {
            let results = try PersistenceController.shared.container.viewContext.fetch(fetchRequest)
            var intermediate = Dictionary(grouping: results) {
                switch stationery {
                case .pen:
                    return $0.pen ?? ""
                case .ink:
                    return $0.ink ?? ""
                case .paper:
                    return $0.paper ?? ""
                }
            }.filter { $0.key != "" }.map { ParameterCount(name: $0.key, count: $0.value.count) }
            if penpal == nil {
                let unusedStationery = Stationery.fetchUnused(for: stationery)
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
    
    func fetchDistinctStationery(ofType stationery: StationeryType) -> [ParameterCount] {
        PenPal.fetchDistinctStationery(ofType: stationery, for: self)
    }
    
    static func fetch(withStatus eventType: EventType? = nil) -> [PenPal] {
        let fetchRequest = NSFetchRequest<PenPal>(entityName: PenPal.entityName)
        if let eventType = eventType {
            fetchRequest.predicate = NSPredicate(format: "lastEventTypeValue = %d", eventType.rawValue)
        }
        do {
            return try PersistenceController.shared.container.viewContext.fetch(fetchRequest)
        } catch {
            dataLogger.error("Could not fetch penpals with status \(eventType?.description ?? "all"): \(error.localizedDescription)")
        }
        return []
    }
    
    func archive(_ value: Bool = true) {
        self.archived = value
        PersistenceController.shared.save()
    }
    
    func update(from contact: CNContact) {
        self.image = contact.thumbnailImageData
        self.initials = contact.initials
        self.name = contact.fullName ?? self.name
        PersistenceController.shared.save()
    }
    
    func delete() {
        PersistenceController.shared.container.viewContext.delete(self)
        PersistenceController.shared.save()
    }
    
    static func syncWithContacts() async {
        
        await PersistenceController.shared.container.performBackgroundTask { context in
            
            let store = CNContactStore()
            let keys = [
                CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
                CNContactOrganizationNameKey,
                CNContactImageDataAvailableKey,
                CNContactThumbnailImageDataKey
            ] as! [CNKeyDescriptor]
            
            let fetchRequest = NSFetchRequest<PenPal>(entityName: PenPal.entityName)
            let penpals = (try? context.fetch(fetchRequest)) ?? []
            let mapping = UserDefaults.shared.penpalContactMap
            
            for penpal in penpals {
                guard let uuid = penpal.id, let contactID = mapping[uuid.uuidString] else { continue }
                do {
                    let contact = try store.unifiedContact(withIdentifier: contactID, keysToFetch: keys)
                    penpal.update(from: contact)
                } catch {
                    appLogger.error("Could not fetch contact with ID \(contactID) \(penpal.wrappedName): \(error.localizedDescription)")
                }
            }
            
            let penpalsWithNoContact: [String: [PenPal]] = Dictionary(grouping: penpals.filter {
                guard let uuid = $0.id else { return false }
                return mapping[uuid.uuidString] == nil
            }, by: { $0.wrappedName })
            
            appLogger.debug("Trying to match \(penpalsWithNoContact.count) penpals")
            if !penpalsWithNoContact.isEmpty {
                let request = CNContactFetchRequest(keysToFetch: keys)
                request.sortOrder = CNContactsUserDefaults.shared().sortOrder
                do {
                    try store.enumerateContacts(with: request) { (contact, stop) in
                        if let matchingPenPals = penpalsWithNoContact[contact.fullName ?? "UNKNOWN CONTACT"] {
                            for penpal in matchingPenPals {
                                appLogger.debug("Setting \(penpal.wrappedName) to contact \(contact.identifier)")
                                UserDefaults.shared.setContactID(for: penpal, to: contact.identifier)
                            }
                        }
                    }
                } catch {
                    dataLogger.error("Could not enumerate contacts: \(error.localizedDescription)")
                }
            }
        }
    }
    
    static func calculateBadgeNumber(toWrite: Bool, toPost: Bool) -> Int {
        var count = 0
        if toWrite {
            count += Self.fetch(withStatus: .received).count
        }
        if toPost {
            count += Self.fetch(withStatus: .written).count
        }
        return count
    }
    
}
