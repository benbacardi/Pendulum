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
    
    func fetchCoreDataPenPal(with id: UUID) -> PenPal? {
        PenPal.fetch(withId: id, from: context)
    }
    
}

// MARK: Fetch functions
extension CoreDataPenPalService {
    
    func fetchSectionedEvents(for penPal: PenPalModel) async -> [EventSection] {
        if let coreDataPenPal = PenPal.fetch(withId: penPal.id, from: context) {
            return sectionEvents(coreDataPenPal.events(from: context, descending: true).map { $0.toEventModel() })
        }
        return []
    }
    
    func fetchPenPal(for id: UUID) -> PenPalModel? {
        if let coreDataPenPal = fetchCoreDataPenPal(with: id) {
            return coreDataPenPal.toPenPalModel()
        }
        return nil
    }
    
}

// MARK: Edit PenPal functions
extension CoreDataPenPalService {
    func update(penPal: PenPalModel, with events: [EventModel]) async -> PenPalModel {
        if let coreDataPenPal = fetchCoreDataPenPal(with: penPal.id) {
            coreDataPenPal.updateLastEventType(saving: true, in: context)
            return fetchPenPal(for: penPal.id) ?? penPal
        }
        return penPal
    }
    func update(penPal: PenPalModel, isArchived: Bool) async -> PenPalModel {
        if let coreDataPenPal = fetchCoreDataPenPal(with: penPal.id) {
            coreDataPenPal.archive(isArchived, in: context)
            return fetchPenPal(for: penPal.id) ?? penPal
        }
        return penPal
    }
}

// MARK: Edit Event functions
extension CoreDataPenPalService {
    func deleteEvent(_ event: EventModel) async {
        if let coreDataEvent = Event.fetch(withId: event.id, from: context) {
            let penPalId = coreDataEvent.penpal?.id
            coreDataEvent.delete(in: context, saving: true)
            PersistenceController.shared.save(context: context)
        }
    }
}
