//
//  PenPalListController.swift
//  Pendulum
//
//  Created by Ben Cardy on 04/11/2022.
//

import Foundation
import GRDB
import SwiftUI
import Contacts

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
            dataLogger.debug("Pen pals changed: \(penpals.count)")
            Task {
                await self.refresh()
            }
        }
    }
    
    private func refresh(with penpals: [PenPal]? = nil) async {
        if let penpals = penpals {
            let result = await self.groupPenPals(with: penpals.filter { $0.dateDeleted == nil })
            DispatchQueue.main.async {
                if self.penpals.isEmpty {
                    self.penpals = penpals
                    self.groupedPenPals = result
                } else {
                    withAnimation {
                        self.penpals = penpals
                        self.groupedPenPals = result
                    }
                }
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
            var key: EventType = penpal.lastEventType
            if penpal.archived {
                key = .archived
            } else if key == .theyReceived {
                /// Group "they received" statuses with "you sent" statuses on the home page
                key = .sent
            }
            if !groups.keys.contains(key) {
                groups[key] = []
            }
            groups[key]?.append(penpal)
        }
        return groups
    }
    
    func syncWithContacts() async {
        let store = CNContactStore()
        let keys = [
            CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
            CNContactOrganizationNameKey,
            CNContactImageDataAvailableKey,
            CNContactThumbnailImageDataKey
        ] as! [CNKeyDescriptor]
        for penpal in self.penpals {
            guard let contactID = penpal.contactID else { continue }
            do {
                let contact = try store.unifiedContact(withIdentifier: contactID, keysToFetch: keys)
                await penpal.update(from: contact)
            } catch {
                dataLogger.error("Could not fetch contact with ID \(contactID) (\(penpal.name)): \(error.localizedDescription)")
            }
        }
        let penpalsWithNoContacts: [String: [PenPal]] = Dictionary(grouping: await AppDatabase.shared.fetchPenPalsWithoutContacts(), by: { $0.name })
        if !penpalsWithNoContacts.isEmpty {
            let request = CNContactFetchRequest(keysToFetch: keys)
            request.sortOrder = CNContactsUserDefaults.shared().sortOrder
            var mappings: [PenPal: CNContact] = [:]
            do {
                try store.enumerateContacts(with: request) { (contact, stop) in
                    if let matchingPenPals = penpalsWithNoContacts[contact.fullName ?? "UNKNOWN CONTACT"] {
                        for penpal in matchingPenPals {
                            mappings[penpal] = contact
                        }
                    }
                }
            } catch {
                dataLogger.error("Could not enumerate contacts: \(error.localizedDescription)")
            }
            if !mappings.isEmpty {
                for (penpal, contact) in mappings {
                    await penpal.update(from: contact)
                }
            }
        }
    }
    
}
