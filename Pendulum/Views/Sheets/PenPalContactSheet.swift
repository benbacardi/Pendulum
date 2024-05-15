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
    @Environment(\.managedObjectContext) var moc
    @Environment(\.presentationMode) var presentationMode
    
    // MARK: State
    @ObservedObject var penpal: PenPal
    @State private var contactID: String? = nil
    @State private var contactsAccessStatus: CNAuthorizationStatus = .notDetermined
    @State private var addresses: [CNLabeledValue<CNPostalAddress>] = []
    @State private var maps: [CLPlacemark?] = []
    @State private var notes: String = ""
    @AppStorage(UserDefaults.Key.stopAskingAboutContacts, store: UserDefaults.shared) private var stopAskingAboutContacts: Bool = false
    @State private var presentingEditSheet: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack {
                
                PenPalHeader(penpal: penpal)
                
                ScrollView {
                    
                    GroupBox {
                        TextField("Notes - postage cost, etc", text: $notes, axis: .vertical)
                    }
                    
                    if contactsAccessStatus != .authorized && !self.stopAskingAboutContacts {
                        ContactsAccessRequiredView(contactsAccessStatus: $contactsAccessStatus, reason: "to fetch any addresses for \(penpal.wrappedName).")
                            .padding(.top)
                    } else {
                        
                        if self.stopAskingAboutContacts {
                            
                            Button(action: {
                                self.presentingEditSheet = true
                            }) {
                                Text("Edit Name and Photo")
                            }
                            .padding()
                            
                        } else {
                            
                            if contactID == nil {
                                
                                Text("\(penpal.wrappedName) is not currently associated with one of your contacts, so Pendulum cannot fetch any addresses.")
                                    .fullWidth(alignment: .center)
                                    .foregroundColor(.secondary)
                                    .padding()
                                
                                Button(action: {
                                    self.presentingEditSheet = true
                                }) {
                                    Text("Edit Name and Photo")
                                }
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
                                
                                Text("To change the name or photo for \(penpal.wrappedName), update their entry in the Contacts app.")
                                    .fullWidth(alignment: .center)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding()
                                
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
                    PersistenceController.shared.save(context: moc)
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Done")
                }
            }
            .navigationTitle("Contact Details")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $presentingEditSheet) {
            ManualAddPenPalSheet(penpal: penpal) { _ in
                self.presentingEditSheet = false
            }
        }
    }
    
}
