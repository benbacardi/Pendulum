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
    @Published var image: Image? = nil
    
    func present(_ image: Image) {
        self.image = image
        self.show = true
    }
    
}
