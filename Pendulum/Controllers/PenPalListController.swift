//
//  PenPalListController.swift
//  Pendulum
//
//  Created by Ben Cardy on 04/11/2022.
//

import Foundation
import GRDB
import SwiftUI

class PenPalListController: ObservableObject {
    
    @Published var penpals: [PenPal] = []
    @Published var groupedPenPals: [EventType: [PenPal]] = [:]
    
    private var penPalObservation = AppDatabase.shared.observePenPalObservation()
    private var penPalObservationCancellable: DatabaseCancellable?
    private var eventObservation = AppDatabase.shared.observeEventObservation()
    private var eventObservationCancellable: DatabaseCancellable?
    
    init() {
        self.penPalObservationCancellable = AppDatabase.shared.start(observation: self.penPalObservation) { error in
            dataLogger.error("Error observing stored pen pals: \(error.localizedDescription)")
        } onChange: { penpals in
            dataLogger.debug("Pen pals changed: \(penpals)")
            Task {
                await self.refresh(with: penpals)
            }
//            self.penpals = penpals
            
//            if let penpal = penpals.last {
//                Task {
//                    let event = Event(id: nil, type: EventType.inbound.rawValue, date: Date(), penpalID: penpal.id)
//                    do {
//                        try await AppDatabase.shared.save(event)
//                    } catch {
//                        print("Could not save event: \(error.localizedDescription)")
//                    }
//                }
//            }
            
//            Task {
//                let result = await self.groupPenPals(with: penpals)
//                DispatchQueue.main.async {
//                    self.groupedPenPals = result
//                }
//            }
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
    
    private func refresh(with penpals: [PenPal]? = nil) async {
        if let penpals = penpals {
            let result = await self.groupPenPals(with: penpals)
            DispatchQueue.main.async {
                self.penpals = penpals
                self.groupedPenPals = result
            }
        } else {
            do {
                let newPenpals = try await AppDatabase.shared.fetchAllPenPals()
                await refresh(with: newPenpals)
            } catch {
                dataLogger.error("Could not fetch penpals: \(error.localizedDescription)")
            }
        }
    }
    
    private func groupPenPals(with penpals: [PenPal]) async -> [EventType: [PenPal]] {
        var groups: [EventType: [PenPal]] = [:]
        for penpal in penpals {
            let key: EventType
            if let latestEvent = await penpal.fetchLatestEvent() {
                key = latestEvent.eventType
            } else {
                key = .noEvent
            }
            if !groups.keys.contains(key) {
                groups[key] = []
            }
            groups[key]?.append(penpal)
        }
        return groups
    }
    
}
