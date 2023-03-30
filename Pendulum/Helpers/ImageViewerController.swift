//
//  ImageViewerController.swift
//  Pendulum
//
//  Created by Ben Cardy on 27/03/2023.
//

import Foundation
import SwiftUI

class ImageViewerController: ObservableObject {
    
    @Published var show: Bool = false
    @Published var image: EventPhoto? = nil
    @Published var images: [EventPhoto] = []
    
    func present(_ images: [EventPhoto], showing: EventPhoto) {
        withAnimation {
            self.show = true
            self.image = showing
            self.images = images
        }
    }
    
    var urls: [URL] {
        self.images.compactMap { $0.temporaryURL() }
    }
    
    func dismiss() {
        withAnimation {
            self.image = nil
            self.images = []
            self.show = false
        }
    }
    
}
