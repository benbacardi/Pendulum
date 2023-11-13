//
//  Event+Extensions.swift
//  Pendulum
//
//  Created by Ben Cardy on 21/11/2022.
//

import CoreData
import Foundation

extension Event {
    
    static let entityName: String = "Event"
    static let optionSeparators = CharacterSet(charactersIn: ";\n")
    
    var wrappedDate: Date {
        self.date ?? .distantPast
    }

    var type: EventType {
        get { return EventType.from(self.typeValue) }
        set { self.typeValue = Int16(newValue.rawValue) }
    }
    
    var letterType: LetterType {
        get { return LetterType.from(self.letterTypeValue) }
        set { self.letterTypeValue = Int16(newValue.rawValue) }
    }
    
    var hasNotes: Bool {
        !(self.notes?.isEmpty ?? true) || self.hasAttributes
    }
    
    var hasAttributes: Bool {
        self.hasStationery || !(self.trackingReference?.isEmpty ?? true)
    }
    
    var hasStationery: Bool {
        !(self.pen?.isEmpty ?? true) || !(self.ink?.isEmpty ?? true) || !(self.paper?.isEmpty ?? true)
    }
    
    var inks: [String] {
        guard let inks = self.ink else { return [] }
        return inks.components(separatedBy: Self.optionSeparators).map { $0.trimmingCharacters(in: .whitespaces) }
    }
    
    var pens: [String] {
        guard let pens = self.pen else { return [] }
        return pens.components(separatedBy: Self.optionSeparators).map { $0.trimmingCharacters(in: .whitespaces) }
    }
    
    var papers: [String] {
        guard let papers = self.paper else { return [] }
        return papers.components(separatedBy: Self.optionSeparators).map { $0.trimmingCharacters(in: .whitespaces) }
    }
    
}

extension Event {
    
    func update(type: EventType, date: Date, notes: String?, pen: String?, ink: String?, paper: String?, letterType: LetterType, ignore: Bool, noFurtherActions: Bool, trackingReference: String? = nil, withPhotos photos: [EventPhoto]? = nil, in context: NSManagedObjectContext, recalculatePenPalEvent: Bool = true, saving: Bool = true) {
        self.date = date
        self.type = type
        self.notes = notes?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.pen = pen?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.ink = ink?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.paper = paper?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.trackingReference = trackingReference?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.letterType = letterType
        self.ignore = ignore
        self.noFurtherActions = noFurtherActions
        
        if let photos {
            dataLogger.debug("There are photos for the event \(self.id?.uuidString ?? "NO ID"): \(photos.count)")
            for photo in photos {
                if photo.event == nil {
                    dataLogger.debug("Photo is new: \(photo.id?.uuidString ?? "NO ID")")
                    self.addToPhotos(photo)
                }
            }
            let deletedCount = self.deletePhotos(notMatching: photos.compactMap { $0.id }, saving: false, in: context)
            dataLogger.debug("Deleted \(deletedCount) old photos")
        }
        
        if recalculatePenPalEvent {
            self.penpal?.updateLastEventType(in: context)
        }
        if saving {
            PersistenceController.shared.save(context: context)
        }
    }
    
    func delete(in context: NSManagedObjectContext, saving: Bool = true) {
        context.delete(self)
        self.penpal?.updateLastEventType(in: context)
        if saving {
            PersistenceController.shared.save(context: context)
        }
    }
    
}

extension Event {
    
    func addPhoto(fromData data: Data, saving: Bool = false, in context: NSManagedObjectContext) {
        let newPhoto = EventPhoto(context: context)
        newPhoto.id = UUID()
        newPhoto.data = data
        self.addToPhotos(newPhoto)
        if saving {
            PersistenceController.shared.save(context: context)
        }
    }
    
    func allPhotos() -> [EventPhoto] {
        Array(photos as? Set<EventPhoto> ?? []).sorted(using: KeyPathComparator(\.dateAdded))
    }
    
    func photoInformationForExport() -> [EventPhoto] {
        let fetchRequest = NSFetchRequest<EventPhoto>(entityName: EventPhoto.entityName)
//        fetchRequest.propertiesToFetch = ["id", "dateAdded"]
        do {
            return try self.managedObjectContext?.fetch(fetchRequest) ?? []
        } catch {
            dataLogger.error("Could not fetch photos: \(error.localizedDescription)")
        }
        return []
    }
    
    func deletePhotos(notMatching ids: [UUID], saving: Bool = false, in context: NSManagedObjectContext) -> Int {
        var deletedCount = 0
        for photo in self.allPhotos() {
            guard let id = photo.id else { continue }
            if !ids.contains(id) {
                deletedCount += 1
                context.delete(photo)
            }
        }
        if saving {
            PersistenceController.shared.save(context: context)
        }
        return deletedCount
    }
    
}

extension Event {
    
    static func fetch(withStatus eventTypes: [EventType]? = nil, from context: NSManagedObjectContext) -> [Event] {
        let fetchRequest = NSFetchRequest<Event>(entityName: Event.entityName)
        var predicates: [NSPredicate] = []
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
    
    static func count(from context: NSManagedObjectContext) -> Int {
        let fetchRequest = NSFetchRequest<Event>(entityName: Event.entityName)
        fetchRequest.resultType = NSFetchRequestResultType.countResultType
        do {
            return try context.count(for: fetchRequest)
        } catch {
            dataLogger.error("Could not fetch events: \(error.localizedDescription)")
        }
        return 0
    }
    
    static func updateStationery(ofType type: StationeryType, from oldName: String, to newName: String, outbound: Bool = true, in context: NSManagedObjectContext) {
        let fetchRequest = NSFetchRequest<Event>(entityName: Event.entityName)
        var predicates: [NSPredicate] = [NSPredicate(format: "\(type.recordType) CONTAINS %@", oldName)]
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
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        dataLogger.debug("Updating \(type.recordType) called \(oldName) to \(newName)")
        do {
            for result in try context.fetch(fetchRequest) {
                switch type {
                case .pen:
                    result.pen = parseStationery(result.pen, replacing: oldName, with: newName)
                case .ink:
                    result.ink = parseStationery(result.ink, replacing: oldName, with: newName)
                case .paper:
                    result.paper = parseStationery(result.paper, replacing: oldName, with: newName)
                }
            }
            PersistenceController.shared.save(context: context)
        } catch {
            dataLogger.error("Could not update stationery: \(error.localizedDescription)")
        }
    }
    
}

extension Event {
    static func deleteAll(in context: NSManagedObjectContext) {
        for event in fetch(from: context) {
            event.delete(in: context, saving: false)
        }
        PersistenceController.shared.save(context: context)
    }
}

func parseStationery(_ data: String?, replacing oldName: String, with newName: String) -> String? {
    guard let data else { return nil }
    return data.trimmingCharacters(in: .whitespacesAndNewlines)
        .components(separatedBy: Event.optionSeparators)
        .map { $0.trimmingCharacters(in: .whitespaces) }
        .map { $0 == oldName ? newName : $0 }
        .uniqued()
        .joined(separator: "\n")
}
