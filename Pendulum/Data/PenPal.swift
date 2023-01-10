//
//  PenPal.swift
//  Pendulum
//
//  Created by Ben Cardy on 09/01/2023.
//

import SwiftUI
import CoreData

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
    
    static func fetch(withStatus eventType: EventType? = nil) -> [PenPal] {
        let fetchRequest = NSFetchRequest<PenPal>(entityName: PenPal.entityName)
        var predicates: [NSPredicate] = [
            NSPredicate(format: "archived = %@", NSNumber(value: false))
        ]
        if let eventType = eventType {
            predicates.append(NSPredicate(format: "lastEventTypeValue = %d", eventType.rawValue))
        }
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        do {
            return try PersistenceController.shared.container.viewContext.fetch(fetchRequest)
        } catch {
            dataLogger.error("Could not fetch penpals with status \(eventType?.description ?? "all"): \(error.localizedDescription)")
        }
        return []
    }
    
}
