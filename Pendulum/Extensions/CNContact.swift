//
//  CNContact.swift
//  Pendulum
//
//  Created by Ben Cardy on 04/11/2022.
//

import Foundation
import Contacts
import SwiftUI

let contactFormatter = CNContactFormatter()

extension CNContact {
    
    var fullName: String? {
        contactFormatter.string(from: self)
    }
    
    var initials: String {
        let givenNamePrefix = String(self.givenName.trimmingCharacters(in: .whitespaces).prefix(1))
        let familyNamePrefix = String(self.familyName.trimmingCharacters(in: .whitespaces).prefix(1))
        let initialCandidates: String
        if givenNamePrefix.isEmpty && familyNamePrefix.isEmpty {
            initialCandidates = "\(self.organizationName.prefix(1))".uppercased()
        } else {
            initialCandidates = "\(givenNamePrefix)\(familyNamePrefix)".uppercased()
        }
        return String(initialCandidates.filter { $0.isLetter || $0.isNumber })
    }
    
    var sortKey: String {
        let key: String
        let familyName = self.familyName.trimmingCharacters(in: .whitespaces)
        if familyName.isEmpty {
            let givenName = self.givenName.trimmingCharacters(in: .whitespaces)
            if givenName.isEmpty {
                let org = self.organizationName.trimmingCharacters(in: .whitespaces)
                if org.isEmpty {
                    key = fullName ?? ""
                } else {
                    key = org
                }
            } else {
                key = givenName
            }
        } else {
            key = familyName
        }
        return key.filter { $0.isLetter || $0.isNumber }.lowercased()
    }
    
    func matches(term: String) -> Bool {
        self.fullName?.contains(term) ?? false
    }
    
    var image: Image? {
        if self.imageDataAvailable, let imageData = self.thumbnailImageData, let image = UIImage(data: imageData) {
            return Image(uiImage: image).resizable()
        }
        return nil
    }
    
}
