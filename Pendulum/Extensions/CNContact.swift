//
//  CNContact.swift
//  Pendulum
//
//  Created by Ben Cardy on 04/11/2022.
//

import Foundation
import Contacts
import SwiftUI

extension CNContact {
    
    var fullName: String {
        "\(self.givenName) \(self.familyName)"
    }
    
    var initials: String {
        "\(self.givenName.prefix(1))\(self.familyName.prefix(1))".uppercased()
    }
    
    var image: Image? {
        if self.imageDataAvailable, let imageData = self.imageData, let image = UIImage(data: imageData) {
            return Image(uiImage: image).resizable()
        }
        return nil
    }
    
}
