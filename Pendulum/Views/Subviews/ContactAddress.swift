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
    var address: CNLabeledValue<CNPostalAddress>? = nil
    @Binding var localAddress: String
    @State private var placemark: CLPlacemark? = nil
    @State private var cameraPosition: MapCameraPosition = .automatic
    @FocusState private var addressFieldIsFocused
    
    var resolvedAddress: String {
        address?.value.getFullAddress() ?? localAddress
    }
    
    var body: some View {
        GroupBox {
            if let address {
                Text(CNLabeledValue<NSString>.localizedString(forLabel: address.label ?? "No label"))
                    .font(.caption)
                    .fullWidth()
                Text(resolvedAddress)
                    .fullWidth()
            } else {
                Text("Address")
                    .font(.caption)
                    .fullWidth()
                TextField("Enter an address", text: $localAddress, axis: .vertical)
                    .multilineTextAlignment(.leading)
                    .fullWidth()
                    .focused($addressFieldIsFocused)
            }
            ZStack {
                Rectangle()
                    .fill(Color.black.opacity(0.05))
                    .frame(height: 100)
                if let placemark = placemark, let location = placemark.location {
                    Button(action: {
                        var urlComponents = URLComponents()
                        urlComponents.scheme = "maps"
                        urlComponents.host = ""
                        urlComponents.path = ""
                        urlComponents.queryItems = [URLQueryItem(name: "address", value: resolvedAddress.replacingOccurrences(of: "\n", with: ", "))]
                        if let url = urlComponents.url {
                            openURL(url)
                        }
                    }) {
                        Map(position: $cameraPosition, interactionModes: []) {
                            Marker("", coordinate: location.coordinate)
                        }
                        .frame(height: 100)
                    }
                }
            }
        }
        .foregroundColor(.primary)
        .task {
            await updatePlacemark()
        }
        .onChange(of: addressFieldIsFocused) {
            if !addressFieldIsFocused {
                Task {
                    await updatePlacemark()
                }
            }
        }
    }
    
    func updatePlacemark() async {
        let location = await getLocationFromAddress(resolvedAddress)
        DispatchQueue.main.async {
            self.placemark = location
            if let loc = location?.location {
                self.cameraPosition = MapCameraPosition.region(.init(center: loc.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)))
            }
        }
    }
    
}
