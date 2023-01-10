//
//  Event+Extensions.swift
//  Pendulum
//
//  Created by Ben Cardy on 21/11/2022.
//

import Foundation

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
