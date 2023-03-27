//
//  EventPhoto+Extensions.swift
//  Pendulum
//
//  Created by Ben Cardy on 27/03/2023.
//

import Foundation
import SwiftUI

extension EventPhoto {
    static let entityName: String = "EventPhoto"
    
    static func from(_ data: Data) -> EventPhoto {
        let eventPhoto = EventPhoto(context: PersistenceController.shared.container.viewContext)
        eventPhoto.id = UUID()
        eventPhoto.data = data
        return eventPhoto
    }
    
    func image() -> Image? {
        guard let data = self.data, let uiImage = UIImage(data: data) else { return nil }
        return Image(uiImage: uiImage)
    }
}
