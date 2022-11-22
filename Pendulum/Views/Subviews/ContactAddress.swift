//
//  ContactAddress.swift
//  Pendulum
//
//  Created by Ben Cardy on 22/11/2022.
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

struct ContactAddress: View {
    
    // MARK: Environment
    @Environment(\.openURL) private var openURL
    
    // MARK: Parameters
    let address: CNLabeledValue<CNPostalAddress>
    let placemark: CLPlacemark?
    
    var body: some View {
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
