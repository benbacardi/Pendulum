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
        !(self.pen?.isEmpty ?? true) || !(self.ink?.isEmpty ?? true) || !(self.paper?.isEmpty ?? true)
    }
    
    var inks: [String] {
        guard let inks = self.ink else { return [] }
        return inks.components(separatedBy: ";").map { $0.trimmingCharacters(in: .whitespaces) }
    }
    
    var pens: [String] {
        guard let pens = self.pen else { return [] }
        return pens.components(separatedBy: ";").map { $0.trimmingCharacters(in: .whitespaces) }
    }
    
    var papers: [String] {
        guard let papers = self.paper else { return [] }
        return papers.components(separatedBy: ";").map { $0.trimmingCharacters(in: .whitespaces) }
    }
    
}

extension Event {
    
    func update(date: Date, notes: String?, pen: String?, ink: String?, paper: String?, letterType: LetterType, ignore: Bool) {
        self.date = date
        self.notes = notes
        self.pen = pen
        self.ink = ink
        self.paper = paper
        self.letterType = letterType
        self.ignore = ignore
        self.penpal?.updateLastEventType()
        PersistenceController.shared.save()
    }
    
    func delete() {
        PersistenceController.shared.container.viewContext.delete(self)
        self.penpal?.updateLastEventType()
        PersistenceController.shared.save()
    }
    
}

extension Event {
    
    static func fetch(withStatus eventTypes: [EventType]? = nil) -> [Event] {
        let fetchRequest = NSFetchRequest<Event>(entityName: Event.entityName)
        var predicates: [NSPredicate] = []
        if let eventTypes = eventTypes {
            predicates.append(
                NSCompoundPredicate(orPredicateWithSubpredicates: eventTypes.map { NSPredicate(format: "typeValue = %d", $0.rawValue) })
            )
        }
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        do {
            return try PersistenceController.shared.container.viewContext.fetch(fetchRequest)
        } catch {
            dataLogger.error("Could not fetch events: \(error.localizedDescription)")
        }
        return []
    }
    
}
