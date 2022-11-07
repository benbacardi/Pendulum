//
//  AddPenPalSheet.swift
//  Pendulum
//
//  Created by Ben Cardy on 04/11/2022.
//

import SwiftUI
import Contacts

struct AddPenPalSheet: View {
    
    // MARK: Environment
    @Environment(\.presentationMode) var presentationMode
    
    // MARK: State
    let existingPenPals: [PenPal]
    @State private var existingPenPalIdentifiers: Set<String> = []
    @State private var contactDetails: [CNContact] = []
    @State private var contactsFetched: Bool = false
    @State private var sortedContacts: [CNContact] = []
    @State private var searchText: String = ""
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(sortedContacts, id: \.identifier) { contact in
                    if !existingPenPalIdentifiers.contains(contact.identifier) {
                        Button(action: {
                            Task {
                                let newPenPal = PenPal(id: contact.identifier, givenName: contact.givenName, familyName: contact.familyName, image: contact.imageData, _lastEventType: EventType.noEvent.rawValue, lastEventDate: nil)
                                do {
                                    try await AppDatabase.shared.save(newPenPal)
                                    presentationMode.wrappedValue.dismiss()
                                } catch {
                                    dataLogger.error("Could not save PenPal: \(error.localizedDescription)")
                                }
                            }
                        }) {
                            HStack {
                                if let image = contact.image {
                                    image
                                        .clipShape(Circle())
                                        .frame(width: 40, height: 40)
                                } else {
                                    ZStack {
                                        Circle()
                                            .fill(.gray)
                                        Text(contact.initials)
                                            .font(.system(.headline, design: .rounded))
                                            .foregroundColor(.white)
                                    }
                                    .frame(width: 40, height: 40)
                                }
                                if let name = contact.fullName {
                                    Text(name)
                                } else {
                                    Text("Unknown Contact")
                                }
                            }
                            .foregroundColor(.primary)
                        }
                    }
                }
            }
            .searchable(text: $searchText)
            .onAppear {
                self.existingPenPalIdentifiers = Set(existingPenPals.map { $0.id })
                Task {
                    let store = CNContactStore()
                    let keys = [
                        CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
                        CNContactOrganizationNameKey,
                        CNContactPostalAddressesKey,
                        CNContactImageDataAvailableKey,
                        CNContactImageDataKey,
                    ] as! [CNKeyDescriptor]
                    let request = CNContactFetchRequest(keysToFetch: keys)
                    DispatchQueue.global(qos: .userInitiated).async {
                        do {
                            try store.enumerateContacts(with: request) { (contact, stop) in
                                if !existingPenPalIdentifiers.contains(contact.identifier) {
                                    DispatchQueue.main.async {
                                        self.contactDetails.append(contact)
                                    }
                                }
                            }
                            DispatchQueue.main.async {
                                self.contactsFetched = true
                            }
                        } catch {
                            dataLogger.error("Could not enumerate contacts: \(error.localizedDescription)")
                        }
                    }
                }
            }
            .navigationBarTitle("Add Pen Pal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Cancel")
                }
            }
            .onChange(of: contactsFetched) { _ in
                self.sortAndFilterContacts()
            }
            .onChange(of: searchText) { searchText in
                self.sortAndFilterContacts(with: searchText)
            }
        }
    }
    
    func sortAndFilterContacts(with searchText: String = "") {
        let st = searchText.lowercased()
        withAnimation {
            self.sortedContacts = contactDetails.filter { contact in
                if contact.fullName == nil {
                    return false
                }
                if st.isEmpty {
                    return true
                }
                return contact.matches(term: st)
            }.sorted { c1, c2 in
                return c1.sortKey < c2.sortKey
            }
        }
    }
    
}

struct AddPenPalSheet_Previews: PreviewProvider {
    static var previews: some View {
        AddPenPalSheet(existingPenPals: [])
    }
}
