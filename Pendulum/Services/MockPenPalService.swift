//
//  MockPenPalService.swift
//  Pendulum
//
//  Created by Ben Cardy on 19/04/2024.
//

import Foundation

class MockPenPalService: PenPalServiceProtocol {
    let name = "MockPenPalService"
    
    static let penPals: [PenPalModel] = [
        .init(id: UUID(), name: "Alex Faber", initials: "AF", notes: nil, lastEventDate: nil, lastEventType: .noEvent, lastEventLetterType: nil, imageData: nil, isArchived: false),
        .init(id: UUID(), name: "Ben Cardy", initials: "BC", notes: nil, lastEventDate: nil, lastEventType: .noEvent, lastEventLetterType: nil, imageData: nil, isArchived: true)
    ]
    
    static let events: [EventModel] = [
        .init(id: UUID(), date: .now, type: .inbound, letterType: .package, notes: nil, noFurtherActions: false, noResponseNeeded: false, paper: [], pens: [], ink: [], trackingReference: nil),
        .init(id: UUID(), date: .now.addingTimeInterval(-100000), type: .sent, letterType: .postcard, notes: "Included something cool.", noFurtherActions: false, noResponseNeeded: true, paper: [], pens: [], ink: [], trackingReference: "LC123532436NL"),
        .init(id: UUID(), date: .now.addingTimeInterval(-100002), type: .sent, letterType: .letter, notes: nil, noFurtherActions: false, noResponseNeeded: true, paper: ["Tomoe River", "Clarefontaine"], pens: ["Jinhao Shark", "TWSBI Eco"], ink: ["RO Sheltered", "Lamy Amazonite"], trackingReference: nil),
    ]
    
    func fetchSectionedEvents(for penPal: PenPalModel) async -> [EventSection] {
        return sectionEvents(Self.events)
    }
}

// MARK: Edit functions
extension MockPenPalService {
    func deleteEvent(_ event: EventModel) async {
        print("Deleting!")
    }
}
