//
//  Event+Extensions.swift
//  Pendulum
//
//  Created by Ben Cardy on 21/11/2022.
//

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
    
}

extension Event {
    
    func update(date: Date, notes: String?, pen: String?, ink: String?, paper: String?, letterType: LetterType) {
        self.date = date
        self.notes = notes
        self.pen = pen
        self.ink = ink
        self.paper = paper
        self.letterType = letterType
        self.penpal?.updateLastEventType()
        PersistenceController.shared.save()
    }
    
    func delete() {
        PersistenceController.shared.container.viewContext.delete(self)
        self.penpal?.updateLastEventType()
        PersistenceController.shared.save()
    }
    
}
