//
//  CDPenPalContactSheet.swift
//  Pendulum
//
//  Created by Ben Cardy on 21/11/2022.
//

import SwiftUI
import Contacts
import CoreLocation
import MapKit

struct CDPenPalContactSheet: View {
    
    // MARK: Environment
    @Environment(\.openURL) private var openURL
    @Environment(\.presentationMode) var presentationMode
    
    // MARK: Parameters
    let penpal: CDPenPal
    
    // MARK: State
    @State private var contactID: String? = nil
    @State private var contactsAccessStatus: CNAuthorizationStatus = .notDetermined
    @State private var addresses: [CNLabeledValue<CNPostalAddress>] = []
    @State private var maps: [CLPlacemark?] = []
    @State private var notes: String = ""
    
    var body: some View {
        NavigationStack {
            VStack {
                
                CDPenPalHeader(penpal: penpal)
                
                ScrollView {
                    
                    GroupBox {
                        TextField("Notes - postage cost, etc", text: $notes, axis: .vertical)
                    }
                    
                    if contactsAccessStatus != .authorized {
                        ContactsAccessRequiredView(contactsAccessStatus: $contactsAccessStatus, reason: "to fetch any addresses \(penpal.wrappedName).")
                    } else {
                        
                        if contactID == nil {
                            
                            Text("\(penpal.wrappedName) is not currently associated with one of your contacts.")
                                .fullWidth(alignment: .center)
                                .padding()
                            
                        } else {
                            
                            if addresses.isEmpty {
                                Text("You have no addresses saved for \(penpal.wrappedName)!")
                                    .fullWidth(alignment: .center)
                            } else {
                                ForEach(Array(zip(addresses, maps)), id: \.0) { address, placemark in
                                    Button(action: {
                                        var urlComponents = URLComponents()
                                        urlComponents.scheme = "maps"
                                        urlComponents.host = ""
                                        urlComponents.path = ""
                                        urlComponents.queryItems = [URLQueryItem(name: "address", value: address.value.getFullAddress(separator: ", "))]
                                        if let url = urlComponents.url {
                                            openURL(url)
                                        }
                                    }) {
                                        GroupBox {
                                            Text(CNLabeledValue<NSString>.localizedString(forLabel: address.label ?? "No label"))
                                                .font(.caption)
                                            //                                    .bold()
                                                .fullWidth()
                                            Text(address.value.getFullAddress())
                                                .fullWidth()
                                            ZStack {
                                                Rectangle()
                                                    .fill(Color.black.opacity(0.05))
                                                    .frame(height: 100)
                                                if let placemark = placemark, let location = placemark.location {
                                                    Map(coordinateRegion: .constant(MKCoordinateRegion(center: location.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005))), interactionModes: [], annotationItems: [IdentifiableLocation(location: location)]) { pin in
                                                        MapMarker(coordinate: pin.location.coordinate, tint: .orange)
                                                    }
                                                    .frame(height: 100)
                                                }
                                            }
                                        }
                                        .foregroundColor(.primary)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding()
            .onAppear {
                self.notes = penpal.notes ?? ""
                self.contactID = UserDefaults.shared.getContactID(for: penpal)
                self.contactsAccessStatus = CNContactStore.authorizationStatus(for: .contacts)
            }
            .task {
                if let contactID = contactID {
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
            .toolbar {
                Button(action: {
                    penpal.notes = notes.isEmpty ? nil : notes
                    do {
                        try PersistenceController.shared.container.viewContext.save()
                    } catch {
                        dataLogger.error("Could not update notes: \(error.localizedDescription)")
                    }
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
