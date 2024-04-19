//
//  PenPalViewModel.swift
//  Pendulum
//
//  Created by Ben Cardy on 18/04/2024.
//

import SwiftUI
import GRDBQuery

class PenPalViewModel: ObservableObject {
    let penPalService: any PenPalServiceProtocol
    
    @Published var events: [EventSection] = []
    @Published var penPal: PenPalModel
    
    init(for penPal: PenPalModel, penPalService: any PenPalServiceProtocol) {
        self.penPal = penPal
        self.penPalService = penPalService
    }
    
    func loadEvents() async {
        let events = await penPalService.fetchSectionedEvents(for: penPal)
        DispatchQueue.main.async {
            self.events = events
        }
    }
    
    func delete(event: EventModel) {
        self.events = self.events.compactMap { eventSection in
            let newSection = eventSection.removingEvent(event)
            if newSection.events.isEmpty {
                return nil
            }
            return newSection
        }
        Task {
            await penPalService.deleteEvent(event)
            if let refreshedPenPal = penPalService.fetchPenPal(for: penPal.id) {
                DispatchQueue.main.async {
                    self.penPal = refreshedPenPal
                }
            }
        }
    }
    
}
