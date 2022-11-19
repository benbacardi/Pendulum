//
//  CDPenPal+Extensions.swift
//  Pendulum
//
//  Created by Ben Cardy on 19/11/2022.
//

import Foundation
import SwiftUI

extension CDPenPal {
    
    var wrappedName: String {
        self.name ?? "Unknown Pen Pal"
    }
    var wrappedInitials: String {
        self.initials ?? "UP"
    }
 
    var lastEventType: EventType {
        return EventType.from(self.lastEventTypeValue)
    }
    
    var displayImage: Image? {
        if let imageData = self.image, let image = UIImage(data: imageData) {
            return Image(uiImage: image).resizable()
        }
        return nil
    }
    
}
