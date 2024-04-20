//
//  PenPalViewModel.swift
//  Pendulum
//
//  Created by Ben Cardy on 18/04/2024.
//

import SwiftUI
import GRDBQuery

@MainActor
class PenPalViewModel: ObservableObject {
    let penPalService: any PenPalServiceProtocol
    
    @Published var eventsBySection: [EventSection] = []
    @Published var penPal: PenPalModel
    
    init(for penPal: PenPalModel, penPalService: any PenPalServiceProtocol) {
        self.penPal = penPal
        self.penPalService = penPalService
    }
    
    func loadEvents() async {
        let events = await penPalService.fetchSectionedEvents(for: penPal)
        self.eventsBySection = events
    }
    
    var events: [EventModel] {
        eventsBySection.flatMap { $0.events }
    }
    
    func delete(event: EventModel) {
        self.eventsBySection = self.eventsBySection.compactMap { eventSection in
            let newSection = eventSection.removingEvent(event)
            if newSection.events.isEmpty {
                return nil
            }
            return newSection
        }
        Task {
            await penPalService.deleteEvent(event)
            self.penPal = await penPalService.update(penPal: penPal, with: self.events)
        }
    }
    
    func toggleArchived() {
        Task {
            self.penPal = await penPalService.update(penPal: self.penPal, isArchived: !self.penPal.isArchived)
        }
    }
    
}
