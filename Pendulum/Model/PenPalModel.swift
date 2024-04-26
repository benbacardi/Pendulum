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
    var eventCount: Int = 0
    
    var displayImage: Image? {
        get async {
            if let imageData = self.imageData, let image = UIImage(data: imageData) {
                return Image(uiImage: image).resizable()
            }
            return nil
        }
    }
    
}

extension PenPalModel {
    var groupingEventType: EventType {
        if isArchived {
            return EventType.archived
        } else {
            switch lastEventType {
            case .noEvent:
                return eventCount == 0 ? EventType.noEvent : EventType.nothingToDo
            case .theyReceived:
                return .sent
            case .written:
                if !UserDefaults.shared.trackPostingLetters {
                    return .sent
                }
                return self.lastEventType
            default:
                return self.lastEventType
            }
        }
    }
}


struct PenPalSection: Identifiable {
    let eventType: EventType
    let penPals: [PenPalModel]
    
    var id: EventType { eventType }
}
