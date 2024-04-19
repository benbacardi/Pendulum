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
    let penPal: PenPalModel
    
    @Published var events: [EventSection] = []
    
    init(for penPal: PenPalModel, penPalService: any PenPalServiceProtocol) {
        self.penPalService = penPalService
        self.penPal = penPal
    }
    
    func loadEvents() async {
        let events = await penPalService.fetchSectionedEvents(for: penPal)
        DispatchQueue.main.async {
            self.events = events
        }
    }
    
    func delete(event: EventModel) {
        print("CALLED")
        self.events = self.events.map {
            $0.removingEvent(event)
        }
        for event in self.events {
            print(event)
            print("--")
        }
//        self.events = self.penPalService.divideEvents(
//            self.events.lazy.map { $0.0 }.filter { $0.id != event.id }
//        )
        Task {
            await penPalService.deleteEvent(event)
        }
    }
    
}
