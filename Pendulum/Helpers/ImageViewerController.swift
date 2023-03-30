//
//  ImageViewerController.swift
//  Pendulum
//
//  Created by Ben Cardy on 27/03/2023.
//

import Foundation
import SwiftUI
import QuickLook


class EventPhotoPreview: NSObject, QLPreviewItem {
     var previewItemURL: URL?
     var previewItemTitle: String?
     
     init(url: URL?, title: String?) {
         previewItemURL = url
         previewItemTitle = title
     }
}


class ImageViewerController: ObservableObject {
    @Published var image: EventPhoto? = nil
    @Published var images: [EventPhoto] = []
    
    func present(_ images: [EventPhoto], showing: EventPhoto) {
        withAnimation {
            self.image = showing
            self.images = images
        }
    }
    
    func dismiss() {
        withAnimation {
            self.image = nil
            self.images = []
        }
    }
    
    var urls: [EventPhotoPreview] {
        self.images.enumerated().compactMap { index, item in
            EventPhotoPreview(url: item.temporaryURL(), title: "Photo \(index + 1)")
        }
    }
    
}
