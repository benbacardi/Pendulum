//
//  CDEvent+Extensions.swift
//  Pendulum
//
//  Created by Ben Cardy on 21/11/2022.
//

import Foundation

extension CDEvent {
    
    static let entityName: String = "CDEvent"
    
    var wrappedDate: Date {
        self.date ?? .distantPast
    }

    var type: EventType {
        get { return EventType.from(self.typeValue) }
        set { self.typeValue = Int16(newValue.rawValue) }
    }
    
    var hasNotes: Bool {
        !(self.notes?.isEmpty ?? true) || self.hasAttributes
    }
    
    var hasAttributes: Bool {
        !(self.pen?.isEmpty ?? true) || !(self.ink?.isEmpty ?? true) || !(self.paper?.isEmpty ?? true)
    }
    
}

extension CDEvent {
    
    func update(date: Date, notes: String?, pen: String?, ink: String?, paper: String?) {
        self.date = date
        self.notes = notes
        self.pen = pen
        self.ink = ink
        self.paper = paper
        do {
            try PersistenceController.shared.container.viewContext.save()
        } catch {
            dataLogger.error("Could not update event: \(error.localizedDescription)")
        }
    }
    
    func delete() {
        PersistenceController.shared.container.viewContext.delete(self)
        self.penpal?.updateLastEventType()
        do {
            try PersistenceController.shared.container.viewContext.save()
        } catch {
            dataLogger.error("Could not delete event: \(error.localizedDescription)")
        }
    }
    
}
