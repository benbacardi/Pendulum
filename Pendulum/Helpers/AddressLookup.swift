//
//  AddressLookup.swift
//  Pendulum
//
//  Created by Ben Cardy on 24/10/2025.
//

import Contacts
import CoreLocation

func getLocationFromAddress(_ address: CNLabeledValue<CNPostalAddress>) async -> CLPlacemark? {
    let geocoder = CLGeocoder()
    do {
        let placemarks = try await geocoder.geocodeAddressString(address.value.getFullAddress(separator: ", "))
        if let addr = placemarks.first {
            return addr
        }
    } catch {
        dataLogger.warning("Could not find map for \(address.value.getFullAddress(separator: ", "))")
    }
    return nil
}
