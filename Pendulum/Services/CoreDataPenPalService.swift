//
//  CoreDataPenPalService.swift
//  Pendulum
//
//  Created by Ben Cardy on 19/04/2024.
//

import Foundation
import CoreData

class CoreDataPenPalService: PenPalServiceProtocol {
    let name = "CoreDataPenPalService"
    let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func fetchSectionedEvents(for penPal: PenPalModel) async -> [EventSection] {
        if let coreDataPenPal = PenPal.fetch(withId: penPal.id, from: context) {
            return sectionEvents(coreDataPenPal.events(from: context, descending: true).map { $0.toEventModel() })
        }
        return []
    }
    
    func fetchPenPal(for id: UUID) -> PenPalModel? {
        if let coreDataPenPal = PenPal.fetch(withId: id, from: context) {
            return coreDataPenPal.toPenPalModel()
        }
        return nil
    }
}

// MARK: Edit functions
extension CoreDataPenPalService {
    func deleteEvent(_ event: EventModel) async {
        if let coreDataEvent = Event.fetch(withId: event.id, from: context) {
            let penPalId = coreDataEvent.penpal?.id
            coreDataEvent.delete(in: context)
            if let penPalId, let coreDataPenPal = PenPal.fetch(withId: penPalId, from: context) {
                coreDataPenPal.updateLastEventType(in: context)
            }
            PersistenceController.shared.save(context: context)
        }
    }
}
