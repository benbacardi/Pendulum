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
    
    func update(date: Date, notes: String?, pen: String?, ink: String?, paper: String?, letterType: LetterType, ignore: Bool, withPictures pictures: [Picture]? = nil) {
        self.date = date
        self.notes = notes
        self.pen = pen
        self.ink = ink
        self.paper = paper
        self.letterType = letterType
        self.ignore = ignore
        if let pictures = pictures {
            dataLogger.debug("There are pictures for the event: \(pictures.count)")
            for picture in pictures {
                if picture.event == nil {
                    dataLogger.debug("Picture is new: \(picture.id?.uuidString ?? "NO ID")")
                    self.addToPictures(picture)
                }
            }
            let deletedCount = self.deletePictures(notMatching: pictures.compactMap { $0.id })
            dataLogger.debug("Deleted \(deletedCount) old pictures")
        }
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
    
    func addPicture(withData data: Data, saving: Bool = false) {
        let newPicture = Picture(context: PersistenceController.shared.container.viewContext)
        newPicture.id = UUID()
        newPicture.data = data
        self.addToPictures(newPicture)
        if saving {
            PersistenceController.shared.save()
        }
    }
    
    func allPictures() -> [Picture] {
        Array(pictures as? Set<Picture> ?? [])
    }
    
    func deletePictures(notMatching ids: [UUID]) -> Int {
        var deletedCount = 0
        for picture in self.allPictures() {
            guard let id = picture.id else { continue }
            if !ids.contains(id) {
                deletedCount += 1
                PersistenceController.shared.container.viewContext.delete(picture)
            }
        }
        return deletedCount
    }
    
}
