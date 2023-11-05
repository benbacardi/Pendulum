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
    
    var lastEventLetterType: LetterType {
        get { return LetterType.from(self.lastEventLetterTypeValue) }
        set { self.lastEventLetterTypeValue = Int16(newValue.rawValue) }
    }
    
    var groupingEventType: EventType {
        if self.archived {
            return EventType.archived
        } else {
            switch self.lastEventType {
            case .noEvent:
                return (self.events?.count ?? 0) == 0 ? EventType.noEvent : EventType.nothingToDo
            case .theyReceived:
                return .sent
            case .written:
                if !UserDefaults.shared.trackPostingLetters {
                    return .sent
                }
                return self.lastEventType
            default:
                return self.lastEventType
            }
        }
    }
    
    var displayImage: Image? {
        if let imageData = self.image, let image = UIImage(data: imageData) {
            return Image(uiImage: image).resizable()
        }
        return nil
    }
    
    var contactID: String? {
        UserDefaults.shared.penpalContactMap[self.id?.uuidString ?? ""]
    }
    
}

extension PenPal {
    
    var ownEventsPredicate: NSPredicate {
        NSPredicate(format: "penpal = %@", self)
    }
    
    func sendLastWrittenEvent(in context: NSManagedObjectContext) {
        let lastWrittenEvent = self.getLastEvent(ofType: .written, from: context)
        self.addEvent(ofType: .sent, letterType: lastWrittenEvent?.letterType ?? .letter, in: context)
    }
    
    func addEvent(id: UUID? = nil, ofType eventType: EventType, date: Date? = Date(), notes: String? = nil, pen: String? = nil, ink: String? = nil, paper: String? = nil, letterType: LetterType = .letter, ignore: Bool = false, trackingReference: String? = nil, withPhotos photos: [EventPhoto]? = nil, in context: NSManagedObjectContext, recalculatePenPalEvent: Bool = true, saving: Bool = true) {
        dataLogger.debug("Adding event of type \(eventType.rawValue) to \(self.wrappedName)")
        let newEvent = Event(context: context)
        newEvent.id = id ?? UUID()
        newEvent.date = date
        newEvent.type = eventType
        newEvent.notes = notes?.trimmingCharacters(in: .whitespacesAndNewlines)
        newEvent.pen = pen?.trimmingCharacters(in: .whitespacesAndNewlines)
        newEvent.ink = ink?.trimmingCharacters(in: .whitespacesAndNewlines)
        newEvent.paper = paper?.trimmingCharacters(in: .whitespacesAndNewlines)
        newEvent.trackingReference = trackingReference?.trimmingCharacters(in: .whitespacesAndNewlines)
        newEvent.letterType = letterType
        newEvent.ignore = ignore
        self.addToEvents(newEvent)
        if let photos {
            dataLogger.debug("There are photos for the event: \(photos.count)")
            for photo in photos {
                newEvent.addToPhotos(photo)
            }
        }
        if recalculatePenPalEvent {
            self.updateLastEventType(in: context)
        }
        if saving {
            PersistenceController.shared.save(context: context)
        }
    }
    
    func setLastEventType(to eventType: EventType, letterType: LetterType, at date: Date?, saving: Bool = false, in context: NSManagedObjectContext) {
        if self.lastEventType != eventType { self.lastEventType = eventType }
        if self.lastEventDate != date { self.lastEventDate = date }
        if self.lastEventLetterType != letterType { self.lastEventLetterType = letterType }
        if saving {
            PersistenceController.shared.save(context: context)
        }
    }
    
    @discardableResult
    func updateLastEventType(saving: Bool = false, in context: NSManagedObjectContext) -> EventType {
        var newEventType: EventType = .noEvent
        var newEventDate: Date? = nil
        var newEventLetterType: LetterType = .letter
        
        var updateFromDb: Bool = true
        if let lastWritten = self.getLastEvent(ofType: .written, from: context) {
            let lastSent = self.getLastEvent(ofType: .sent, from: context)
            if lastSent?.date ?? .distantPast < lastWritten.date ?? .distantPast {
                newEventType = .written
                newEventDate = lastWritten.date
                newEventLetterType = lastWritten.letterType
                updateFromDb = false
            }
        }
        
        if updateFromDb, let lastEvent = self.getLastEvent(from: context) {
            newEventType = lastEvent.type
            newEventDate = lastEvent.date
            newEventLetterType = lastEvent.letterType
        }
        
        dataLogger.debug("Setting the Last Event Type for \(self.wrappedName) to \(newEventType.description(for: newEventLetterType)) at \(newEventDate?.timeIntervalSince1970 ?? 0)")
        self.setLastEventType(to: newEventType, letterType: newEventLetterType, at: newEventDate, saving: saving, in: context)
        
        if newEventType == .received {
            self.scheduleShouldWriteBackNotification(countingFrom: newEventDate)
        } else {
            self.cancelShouldWriteBackNotification()
        }
        
        UIApplication.shared.updateBadgeNumber()
        
        Task {
            await Self.scheduleShouldPostLettersNotification()
        }
        
        return newEventType
        
    }
    
    func getLastEvent(ofType eventType: EventType? = nil, includingIgnoredEvents: Bool = false, from context: NSManagedObjectContext) -> Event? {
        let fetchRequest = NSFetchRequest<Event>(entityName: Event.entityName)
        fetchRequest.fetchLimit = 1
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        var predicates: [NSPredicate] = [
            self.ownEventsPredicate,
        ]
        if let eventType = eventType {
            predicates.append(eventType.predicate)
        }
        if !includingIgnoredEvents {
            predicates.append(NSPredicate(format: "ignore == %@", NSNumber(value: false)))
        }
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        do {
            return try context.fetch(fetchRequest).first
        } catch {
            dataLogger.error("Could not fetch events of type \(eventType?.description ?? "any") for \(self.wrappedName): \(error.localizedDescription)")
        }
        return nil
    }
    
    func fetchPriorEvent(to date: Date, ofType eventType: EventType, ignore: Bool = true, from context: NSManagedObjectContext) -> Event? {
        let fetchRequest = NSFetchRequest<Event>(entityName: Event.entityName)
        fetchRequest.fetchLimit = 1
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        var predicates = [
            self.ownEventsPredicate,
            eventType.predicate,
            NSPredicate(format: "date < %@", date as NSDate),
        ]
        if ignore {
            predicates.append(NSPredicate(format: "ignore == %@", NSNumber(value: false)))
        }
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        do {
            return try context.fetch(fetchRequest).first
        } catch {
            dataLogger.error("Could not fetch prior events of type \(eventType.description) for \(self.wrappedName): \(error.localizedDescription)")
        }
        return nil
    }
    
    static func fetchDistinctStationery(ofType stationery: StationeryType, for penpal: PenPal? = nil, sortAlphabetically: Bool = false, outbound: Bool = true, from context: NSManagedObjectContext) -> [ParameterCount] {
        let fetchRequest = NSFetchRequest<Event>(entityName: Event.entityName)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: stationery.rawValue, ascending: true)]
        var predicates: [NSCompoundPredicate] = []
        if let penpal = penpal {
            predicates.append(NSCompoundPredicate(type: .and, subpredicates: [penpal.ownEventsPredicate]))
        }
        if outbound {
            predicates.append(NSCompoundPredicate(type: .or, subpredicates: [
                EventType.sent.predicate,
                EventType.written.predicate,
            ]))
        } else {
            predicates.append(NSCompoundPredicate(type: .or, subpredicates: [
                EventType.received.predicate
            ]))
        }
        fetchRequest.predicate = NSCompoundPredicate(type: .and, subpredicates: predicates)
        do {
            let results = try context.fetch(fetchRequest)
            
            var pending: [String: Int] = [:]
            
            for event in results {
                let keys: [String]
                switch stationery {
                case .pen:
                    keys = event.pens
                case .ink:
                    keys = event.inks
                case .paper:
                    keys = event.papers
                }
                for key in keys {
                    pending[key] = (pending[key] ?? 0) + 1
                }
            }
            
            var intermediate = pending.map { ParameterCount(name: $0.key, count: $0.value, type: stationery) }
            
            if penpal == nil && outbound {
                let unusedStationery = Stationery.fetchUnused(for: stationery, from: context)
                let setOfResults = Set(intermediate.map { $0.name })
                for item in unusedStationery {
                    if !setOfResults.contains(item) {
                        intermediate.append(ParameterCount(name: item, count: 0, type: stationery))
                    }
                }
            }
            if sortAlphabetically {
                return intermediate.sorted(using: KeyPathComparator(\.name))
            } else {
                return intermediate.sorted()
            }
        } catch {
            dataLogger.error("Could not fetch distinct stationery: \(error.localizedDescription)")
        }
        return []
    }
    
    func fetchDistinctStationery(ofType stationery: StationeryType, sortAlphabetically: Bool = false, outbound: Bool = true, from context: NSManagedObjectContext) -> [ParameterCount] {
        PenPal.fetchDistinctStationery(ofType: stationery, for: self, sortAlphabetically: sortAlphabetically, outbound: outbound, from: context)
    }
    
    static func fetch(withStatus eventType: EventType? = nil, all: Bool = false, from context: NSManagedObjectContext) -> [PenPal] {
        let fetchRequest = NSFetchRequest<PenPal>(entityName: PenPal.entityName)
        var predicates: [NSPredicate] = []
        if !all {
            predicates.append(NSPredicate(format: "archived = %@", NSNumber(value: false)))
        }
        if let eventType = eventType {
            predicates.append(NSPredicate(format: "lastEventTypeValue = %d", eventType.rawValue))
        }
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        do {
            return try context.fetch(fetchRequest)
        } catch {
            dataLogger.error("Could not fetch penpals with status \(eventType?.description ?? "all"): \(error.localizedDescription)")
        }
        return []
    }
    
    static func fetchAll(from context: NSManagedObjectContext) -> [PenPal] {
        return fetch(all: true, from: context)
    }
    
    func archive(_ value: Bool = true, in context: NSManagedObjectContext) {
        self.archived = value
        PersistenceController.shared.save(context: context)
    }
    
    func update(from contact: CNContact, saving: Bool = true, in context: NSManagedObjectContext) {
        dataLogger.debug("Updating \(self.wrappedName) using \(contact.fullName ?? "UNKNOWN CONTACT")")
        if self.image != contact.thumbnailImageData { self.image = contact.thumbnailImageData }
        if self.initials != contact.initials { self.initials = contact.initials }
        if self.name != contact.fullName { self.name = contact.fullName }
        dataLogger.debug("New Values: \(self.wrappedInitials) - \(self.wrappedName)")
        self.updateLastEventType(in: context)
        if saving {
            PersistenceController.shared.save(context: context)
        }
    }
    
    func update(name: String, initials: String, image: Data?, in context: NSManagedObjectContext) {
        if self.name != name { self.name = name }
        if self.initials != initials { self.initials = initials }
        if self.image != image { self.image = image }
        PersistenceController.shared.save(context: context)
    }
    
    func delete(in context: NSManagedObjectContext, saving: Bool = true) {
        context.delete(self)
        if saving {
            PersistenceController.shared.save(context: context)
        }
    }
    
    func syncWithContact() {
        
        appLogger.debug("Syncing \(self.wrappedName) with contacts")
        
        if CNContactStore.authorizationStatus(for: .contacts) == .authorized && !UserDefaults.shared.stopAskingAboutContacts {
            
            appLogger.debug("Authorisation")
            
            let store = CNContactStore()
            let keys = [
                CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
                CNContactOrganizationNameKey,
                CNContactImageDataAvailableKey,
                CNContactThumbnailImageDataKey
            ] as! [CNKeyDescriptor]
            
            if let uuid = self.id {
                let mapping = UserDefaults.shared.penpalContactMap
                
                appLogger.debug("Fetched mapping: \(mapping)")
                appLogger.debug("This ID: \(uuid)")
                
                if let contactID = mapping[uuid.uuidString] {
                    do {
                        appLogger.debug("Fetching contact \(contactID) for \(self.wrappedName)")
                        let contact = try store.unifiedContact(withIdentifier: contactID, keysToFetch: keys)
                        self.update(from: contact, in: PersistenceController.shared.container.viewContext)
                    } catch {
                        appLogger.error("Could not fetch contact with ID \(contactID) \(self.wrappedName): \(error.localizedDescription)")
                    }
                } else {
                    appLogger.debug("No mapping found, searching contacts")
                    let request = CNContactFetchRequest(keysToFetch: keys)
                    request.sortOrder = CNContactsUserDefaults.shared().sortOrder
                    DispatchQueue.global(qos: .userInitiated).async {
                        do {
                            try store.enumerateContacts(with: request) { (contact, stop) in
                                if contact.fullName == self.wrappedName {
                                    appLogger.debug("Setting \(self.wrappedName) to contact \(contact.identifier)")
                                    UserDefaults.shared.setContactID(for: self, to: contact.identifier)
                                }
                            }
                        } catch {
                            appLogger.error("Could not enumerate contacts: \(error.localizedDescription)")
                        }
                    }
                }
            }
            
        }
        
    }
    
    static func calculateBadgeNumber(toWrite: Bool, toPost: Bool) -> Int {
        appLogger.debug("Calcuating badge - showing to reply? \(toWrite) - showing to post? \(toPost)")
        var count = 0
        if toWrite {
            count += Self.fetch(withStatus: .received, from: PersistenceController.shared.container.viewContext).count
        }
        if toPost {
            count += Self.fetch(withStatus: .written, from: PersistenceController.shared.container.viewContext).count
        }
        return count
    }
    
    func events(withStatus eventTypes: [EventType]? = nil, from context: NSManagedObjectContext) -> [Event] {
        let fetchRequest = NSFetchRequest<Event>(entityName: Event.entityName)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        var predicates: [NSPredicate] = [
            self.ownEventsPredicate
        ]
        if let eventTypes = eventTypes {
            predicates.append(
                NSCompoundPredicate(orPredicateWithSubpredicates: eventTypes.map { NSPredicate(format: "typeValue = %d", $0.rawValue) })
            )
        }
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        do {
            return try context.fetch(fetchRequest)
        } catch {
            dataLogger.error("Could not fetch events: \(error.localizedDescription)")
        }
        return []
    }
    
    static func averageTimeToRespond(from context: NSManagedObjectContext) -> Double {
        
        var durations: [Int] = []
        let today = Date()
        
        for penpal in PenPal.fetch(from: context) {
            dataLogger.debug("Fetching events for \(penpal.wrappedName)")
            var fromEvent: Event? = nil
            for event in penpal.events(withStatus: [.received, .written, .sent], from: context) {
                if !event.ignore {
                    dataLogger.debug("Handling event: \(event.type.actionableTextShort) - \(event.wrappedDate)")
                    if event.type == .received {
                        fromEvent = event
                        continue
                    }
                    if let calcFromEvent = fromEvent, event.type == .sent || event.type == .written {
                        dataLogger.debug("Counting days to \(event.type.actionableTextShort) - \(event.wrappedDate)")
                        durations.append(Calendar.current.numberOfDaysBetween(calcFromEvent.wrappedDate, and: event.wrappedDate))
                        fromEvent = nil
                        continue
                    }
                }
            }
            if penpal.lastEventType == .received, let receivedDate = penpal.lastEventDate {
                durations.append(Calendar.current.numberOfDaysBetween(receivedDate, and: today))
            }
        }
        
        if durations.isEmpty {
            return 0
        }
        
        let average = Double(durations.reduce(0, +)) / Double(durations.count)
        dataLogger.debug("Durations: \(durations) - Average: \(average)")
        return average
    }
    
}

extension PenPal {
    static func deleteAll(in context: NSManagedObjectContext) {
        for penpal in fetchAll(from: context) {
            penpal.delete(in: context, saving: false)
        }
        PersistenceController.shared.save(context: context)
    }
}

extension PenPal {
    
    @discardableResult
    static func add(id: UUID? = nil, name: String, initials: String, image: Data? = nil, notes: String? = nil, archived: Bool = false, to context: NSManagedObjectContext, saving: Bool = true) -> PenPal {
        let newPenPal = PenPal(context: context)
        newPenPal.id = id ?? UUID()
        newPenPal.name = name
        newPenPal.initials = initials
        newPenPal.image = image
        newPenPal.lastEventType = EventType.noEvent
        newPenPal.notes = notes
        newPenPal.archived = archived
        if saving {
            PersistenceController.shared.save(context: context)
        }
        return newPenPal
    }
    
    static func restore(_ data: [ExportedPenPal], to context: NSManagedObjectContext, saving: Bool = true) -> ImportResult {
        let allPenPals = Dictionary(grouping: Self.fetchAll(from: context)) { $0.id ?? UUID() }
        var penpalCount: Int = 0
        var eventCount: Int = 0
        var photoCount: Int = 0
        for importItem in data {
            let penpal: PenPal
            var penpalEvents: [UUID: [Event]] = [:]
            
            if let existingPenpal = allPenPals[importItem.id]?.first {
                // Find existing penpal
                penpal = existingPenpal
                penpalEvents = Dictionary(grouping: existingPenpal.events(from: context)) { $0.id ?? UUID() }
            } else {
                // Create new penpal
                penpal = PenPal.add(id: importItem.id, name: importItem.name, initials: importItem.initials, image: nil, notes: importItem.notes, archived: importItem.archived, to: context, saving: false)
            }
            penpalCount += 1
            
            for event in importItem.events {
                // Ignore events where we don't recognise the type
                guard let eventType = EventType(rawValue: event.type), let letterType = LetterType(rawValue: event.letterType) else { continue }
                
                // Find existing event and associated photos
                let existingEvent = penpalEvents[event.id]?.first
                var existingPhotos: [UUID: [EventPhoto]] = [:]
                if let existingEvent = existingEvent {
                    existingPhotos = Dictionary(grouping: existingEvent.allPhotos()) { $0.id ?? UUID() }
                }
                
                // Create photo objects
                var photos: [EventPhoto] = []
//                for photo in event.photos {
//                    guard let data = photo.data else { continue }
//                    if let existingPhoto = existingPhotos[photo.id]?.first {
//                        photos.append(existingPhoto)
//                    } else {
//                        photos.append(EventPhoto.from(data, id: photo.id, dateAdded: photo.dateAdded, thumbnailData: photo.thumbnailData, in: context))
//                    }
//                    photoCount += 1
//                }
                
                if let existingEvent = existingEvent {
                    // Update existing event with new photos
                    existingEvent.update(type: existingEvent.type, date: existingEvent.wrappedDate, notes: existingEvent.notes, pen: existingEvent.pen, ink: existingEvent.ink, paper: existingEvent.paper, letterType: existingEvent.letterType, ignore: existingEvent.ignore, trackingReference: existingEvent.trackingReference, withPhotos: photos, in: context, recalculatePenPalEvent: false, saving: false)
                } else {
                    // Add new event
                    penpal.addEvent(id: event.id, ofType: eventType, date: event.date, notes: event.notes, pen: event.pen, ink: event.ink, paper: event.paper, letterType: letterType, ignore: event.ignore, trackingReference: event.trackingReference, withPhotos: photos, in: context, recalculatePenPalEvent: false, saving: false)
                }
                eventCount += 1
            }
            penpal.updateLastEventType(saving: false, in: context)
        }
        if saving {
            PersistenceController.shared.save(context: context)
        }
        return ImportResult(stationeryCount: 0, penPalCount: penpalCount, eventCount: eventCount, photoCount: photoCount)
    }
}
