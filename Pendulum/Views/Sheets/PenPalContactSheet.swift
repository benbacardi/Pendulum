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
    @State private var notes: String = ""
    @State private var localAddress: String = ""
    @State private var localLocation: CLPlacemark? = nil
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
                            
                            ContactAddress(localAddress: $localAddress)
                            
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
                                    ForEach(addresses, id: \.self) { address in
                                        ContactAddress(address: address, localAddress: .constant(""))
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
                self.localAddress = penpal.address ?? ""
                if !self.stopAskingAboutContacts {
                    let contactID = UserDefaults.shared.getContactID(for: penpal)
                    let addresses = penpal.getContactAddresses()
                    print("BEN: \(addresses)")
                    DispatchQueue.main.async {
                        self.contactID = contactID
                        self.addresses = addresses
                    }
                } else {
                    let location = await getLocationFromAddress(localAddress)
                    DispatchQueue.main.async {
                        self.localLocation = location
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Label("Cancel", systemImage: "xmark")
                            .labelStyleIconOnlyOn26()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        penpal.notes = notes.isEmpty ? nil : notes
                        penpal.address = localAddress.isEmpty ? nil : localAddress
                        PersistenceController.shared.save(context: moc)
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Label("Done", systemImage: "checkmark")
                            .labelStyleIconOnlyOn26()
                    }
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
