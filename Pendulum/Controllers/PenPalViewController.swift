//
//  PenPalViewController.swift
//  Pendulum
//
//  Created by Ben Cardy on 05/11/2022.
//

import Foundation
import GRDB
import SwiftUI

class PenPalViewController: ObservableObject {
    
    let penpal: PenPal
    
    @Published var events: [Event] = []
    @Published var eventsWithDifferences: [(Event, Int)] = []
    
    private var penPalObservation = AppDatabase.shared.observePenPalObservation()
    private var penPalObservationCancellable: DatabaseCancellable?
    private var eventObservation = AppDatabase.shared.observeEventObservation()
    private var eventObservationCancellable: DatabaseCancellable?
    
    init(penpal: PenPal) {
        self.penpal = penpal
    }
    
    func start() {
        self.penPalObservationCancellable = AppDatabase.shared.start(observation: self.penPalObservation) { error in
            dataLogger.error("Error observing stored pen pals: \(error.localizedDescription)")
        } onChange: { penpals in
            dataLogger.debug("Pen pals changed: \(penpals)")
            Task {
                await self.refresh()
            }
        }
        self.eventObservationCancellable = AppDatabase.shared.start(observation: self.eventObservation) { error in
            dataLogger.error("Error observing events: \(error.localizedDescription)")
        } onChange: { events in
            dataLogger.debug("Events changed")
            Task {
                await self.refresh()
            }
        }
    }
    
    private func refresh() async {
        let fetchedEvents = await penpal.fetchAllEvents()
        DispatchQueue.main.async {
            if self.events.isEmpty {
                self.events = fetchedEvents
                self.setDifferences(for: fetchedEvents)
            } else {
                withAnimation {
                    self.events = fetchedEvents
                    self.setDifferences(for: fetchedEvents)
                }
            }
        }
    }
    
    private func setDifferences(for events: [Event]) {
        self.eventsWithDifferences = []
        let calendar = Calendar.current
        for (index, item) in events.enumerated() {
            if index == 0 {
                self.eventsWithDifferences.append((item, 0))
                continue
            }
            let newIndex = index - 1
            let newItem = events[newIndex]
            self.eventsWithDifferences.append((item, calendar.numberOfDaysBetween(item.date, and: newItem.date)))
        }
    }
    
}