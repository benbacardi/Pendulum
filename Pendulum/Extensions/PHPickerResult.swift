//
//  PHPickerResult.swift
//  Pendulum
//
//  Created by Ben Cardy on 05/04/2023.
//

import Foundation
import PhotosUI

extension PHPickerResult {
    
    func fetchImage(_ onImageLoad: @escaping (UIImage) -> Void) {
        if itemProvider.canLoadObject(ofClass: UIImage.self) {
            itemProvider.loadObject(ofClass: UIImage.self) { (image, error) in
                if let image = image as? UIImage {
                    onImageLoad(image)
                }
            }
        }
    }
    
}
