//
//  PenPalContactSheet.swift
//  Pendulum
//
//  Created by Ben Cardy on 21/11/2022.
//

import SwiftUI
import Contacts
import CoreLocation

struct PenPalContactSheet: View {
    
    // MARK: Environment
    @Environment(\.openURL) private var openURL
    @Environment(\.presentationMode) var presentationMode
    
    // MARK: Parameters
    let penpal: PenPal
    
    // MARK: State
    @State private var contactID: String? = nil
    @State private var contactsAccessStatus: CNAuthorizationStatus = .notDetermined
    @State private var addresses: [CNLabeledValue<CNPostalAddress>] = []
    @State private var maps: [CLPlacemark?] = []
    @State private var notes: String = ""
    @AppStorage(UserDefaults.Key.stopAskingAboutContacts.rawValue, store: UserDefaults.shared) private var stopAskingAboutContacts: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack {
                
                PenPalHeader(penpal: penpal)
                
                ScrollView {
                    
                    GroupBox {
                        TextField("Notes - postage cost, etc", text: $notes, axis: .vertical)
                    }
                    
                    if contactsAccessStatus != .authorized && !self.stopAskingAboutContacts {
                        ContactsAccessRequiredView(contactsAccessStatus: $contactsAccessStatus, reason: "to fetch any addresses \(penpal.wrappedName).")
                            .padding(.top)
                    } else if !self.stopAskingAboutContacts {
                        
                        if contactID == nil {
                            
                            Text("\(penpal.wrappedName) is not currently associated with one of your contacts, so Pendulum cannot fetch any addresses.")
                                .fullWidth(alignment: .center)
                                .foregroundColor(.secondary)
                                .padding()
                            
                        } else {
                            
                            if addresses.isEmpty {
                                Text("You have no addresses saved for \(penpal.wrappedName)!")
                                    .fullWidth(alignment: .center)
                                    .padding()
                            } else {
                                ForEach(Array(zip(addresses, maps)), id: \.0) { address, placemark in
                                    ContactAddress(address: address, placemark: placemark)
                                }
                            }
                        }
                    }
                }
            }
            .padding()
            .onAppear {
                self.contactsAccessStatus = CNContactStore.authorizationStatus(for: .contacts)
            }
            .task {
                self.notes = penpal.notes ?? ""
                if !self.stopAskingAboutContacts {
                    self.contactID = UserDefaults.shared.getContactID(for: penpal)
                    if let contactID = self.contactID {
                        let store = CNContactStore()
                        let keys = [
                            CNContactPostalAddressesKey,
                        ] as! [CNKeyDescriptor]
                        do {
                            let contact = try store.unifiedContact(withIdentifier: contactID, keysToFetch: keys)
                            self.addresses = contact.postalAddresses
                            self.maps = self.addresses.map { _ in
                                nil
                            }
                            let geocoder = CLGeocoder()
                            for (index, address) in self.addresses.enumerated() {
                                do {
                                    let placemarks = try await geocoder.geocodeAddressString(address.value.getFullAddress(separator: ", "))
                                    if let addr = placemarks.first {
                                        withAnimation {
                                            self.maps[index] = addr
                                        }
                                    }
                                } catch {
                                    dataLogger.warning("Could not find map for \(address.value.getFullAddress(separator: ", "))")
                                }
                            }
                        } catch {
                            dataLogger.error("Could not fetch contact with ID \(contactID): \(error.localizedDescription)")
                        }
                    }
                }
            }
            .toolbar {
                Button(action: {
                    penpal.notes = notes.isEmpty ? nil : notes
                    PersistenceController.shared.save()
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Done")
                }
            }
            .navigationTitle("Contact Details")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
}
