//
//  PenPalContactSheet.swift
//  Pendulum
//
//  Created by Ben Cardy on 06/11/2022.
//

import SwiftUI
import Contacts
import CoreLocation
import MapKit

struct IdentifiableLocation: Identifiable {
    let id: UUID
    let location: CLLocation
    init(id: UUID = UUID(), location: CLLocation) {
        self.id = id
        self.location = location
    }
}

struct PenPalContactSheet: View {
    
    // MARK: Environment
    @Environment(\.openURL) private var openURL
    
    // MARK: Parameters
    let penpal: PenPal
    
    // MARK: State
    @State private var addresses: [CNLabeledValue<CNPostalAddress>] = []
    @State private var maps: [CLPlacemark?] = []
    
    var body: some View {
        VStack {
            
            PenPalHeader(penpal: penpal)
            
            ScrollView {
                if addresses.isEmpty {
                    Text("You have no addresses saved for \(penpal.name)!")
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
        .padding()
        .onAppear {
            Task {
                let store = CNContactStore()
                let keys = [
                    CNContactPostalAddressesKey,
                ] as! [CNKeyDescriptor]
                do {
                    let contact = try store.unifiedContact(withIdentifier: penpal.id, keysToFetch: keys)
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
                    dataLogger.error("Could not fetch contact with ID \(penpal.id): \(error.localizedDescription)")
                }
            }
        }
        .navigationTitle("Contact Details")
        .navigationBarTitleDisplayMode(.inline)
    }
    
}