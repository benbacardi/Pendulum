//
//  PenPalModel.swift
//  Pendulum
//
//  Created by Ben Cardy on 19/04/2024.
//

import Foundation
import SwiftUI

struct PenPalModel: Identifiable {
    let id: UUID
    let name: String
    let initials: String
    let notes: String?
    let lastEventDate: Date?
    let lastEventType: EventType
    let lastEventLetterType: LetterType?
    let imageData: Data?
    let isArchived: Bool
    
    var displayImage: Image? {
        get async {
            if let imageData = self.imageData, let image = UIImage(data: imageData) {
                return Image(uiImage: image).resizable()
            }
            return nil
        }
    }
    
}
