//
//  PenPalServiceProtocol.swift
//  Pendulum
//
//  Created by Ben Cardy on 19/04/2024.
//

import SwiftUI

private struct PenPalServiceKey: EnvironmentKey {
    static let defaultValue: any PenPalServiceProtocol = MockPenPalService()
}

extension EnvironmentValues {
    var penPalService: any PenPalServiceProtocol {
        get { self[PenPalServiceKey.self] }
        set { self[PenPalServiceKey.self] = newValue }
    }
}

protocol PenPalServiceProtocol {
    var name: String { get }
    
    // MARK: Utility functions
    func sectionEvents(_ events: [EventModel]) -> [EventSection]
    
    // MARK: Display functions
    func fetchSectionedEvents(for penPal: PenPalModel) async -> [EventSection]
    func fetchPenPal(for id: UUID) -> PenPalModel?
    
    // MARK: PenPal edit functions
    func update(penPal: PenPalModel, with events: [EventModel]) async -> PenPalModel
    func update(penPal: PenPalModel, isArchived: Bool) async -> PenPalModel
    
    // MARK: Event edit functions
    func deleteEvent(_ event: EventModel) async
    
}

extension PenPalServiceProtocol {
    var name: String { "PenPalServiceProtocol" }
    
    func sectionEvents(_ events: [EventModel]) -> [EventSection] {
        if events.isEmpty {
            return []
        }
        let calendar = Calendar.current
        var previousDate: Date = .now
        var returnData: [EventSection] = []
        var currentEvents: [EventModel] = []
        var priorDaysBetween: Int = 0
        for event in events {
            let daysBetween = calendar.numberOfDaysBetween(event.date, and: previousDate)
            if daysBetween == 0 {
                currentEvents.append(event)
            } else {
                if !currentEvents.isEmpty {
                    returnData.append(EventSection(dayInterval: priorDaysBetween, events: currentEvents, calculatedFromToday: returnData.isEmpty))
                }
                currentEvents = [event]
                priorDaysBetween = daysBetween
            }
            previousDate = event.date
        }
        if !currentEvents.isEmpty {
            returnData.append(EventSection(dayInterval: priorDaysBetween, events: currentEvents, calculatedFromToday: returnData.isEmpty))
        }
        return returnData
    }
    
}
