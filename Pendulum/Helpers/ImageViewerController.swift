//
//  ImageViewerController.swift
//  Pendulum
//
//  Created by Ben Cardy on 27/03/2023.
//

import Foundation
import SwiftUI

class ImageViewerController: ObservableObject {
    
    @Published var show: Bool = true
    @Published var image: Image? = nil
    @Published var images: [EventPhoto] = []
    
    func present(_ image: Image) {
        withAnimation {
            self.image = image
            self.show = true
        }
    }
    
    func present(_ images: [EventPhoto]) {
        withAnimation {
            self.images = images
        }
    }
    
    func dismiss() {
        withAnimation {
            self.image = nil
            self.images = []
            self.show = false
        }
    }
    
}
