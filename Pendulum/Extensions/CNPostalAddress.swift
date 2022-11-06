//
//  CNPostalAddress.swift
//  Pendulum
//
//  Created by Ben Cardy on 06/11/2022.
//

import Foundation
import Contacts

extension CNPostalAddress {
    
    var fullAddress: String {
        let parts: [String] = [
            self.street,
            self.subLocality,
            self.city,
            self.subAdministrativeArea,
            self.state,
            self.postalCode,
        ]
        return parts.filter { $0 != "" }
            .joined(separator: "\n")
    }
    
}
