//
//  CNPostalAddress.swift
//  Pendulum
//
//  Created by Ben Cardy on 06/11/2022.
//

import Foundation
import Contacts

extension CNPostalAddress {
    
    func getFullAddress(separator: String = "\n") -> String {
        let parts: [String] = [
            self.street,
            self.subLocality,
            self.city,
            self.subAdministrativeArea,
            self.state,
            self.postalCode,
            self.country
        ]
        return parts.filter { $0 != "" }
            .joined(separator: separator)
    }
    
}
