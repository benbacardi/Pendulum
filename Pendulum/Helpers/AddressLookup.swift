//
//  AddressLookup.swift
//  Pendulum
//
//  Created by Ben Cardy on 24/10/2025.
//

import Contacts
import CoreLocation

func getLocationFromAddress(_ address: CNLabeledValue<CNPostalAddress>) async -> CLPlacemark? {
    return await getLocationFromAddress(address.value.getFullAddress())
}

func getLocationFromAddress(_ address: String) async -> CLPlacemark? {
    let geocoder = CLGeocoder()
    do {
        let placemarks = try await geocoder.geocodeAddressString(address.replacingOccurrences(of: "\n", with: ", "))
        if let addr = placemarks.first {
            return addr
        }
    } catch {
        dataLogger.warning("Could not find map for \(address.replacingOccurrences(of: "\n", with: ", "))")
    }
    return nil
}
