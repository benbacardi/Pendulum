//
//  ImagePickerView.swift
//  Pendulum
//
//  Created by Ben Cardy on 27/03/2023.
//

import SwiftUI
import PhotosUI


struct PHImagePickerView: UIViewControllerRepresentable {
    
    private let handleImages: ([PHPickerResult]) -> Void
    private let onDismiss: (Int) -> Void
    
    public init(handleImages: @escaping ([PHPickerResult]) -> Void, onDismiss: @escaping (Int) -> Void) {
        self.handleImages = handleImages
        self.onDismiss = onDismiss
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
        
    public func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.selectionLimit = 10
        configuration.filter = .images
        let controller = PHPickerViewController(configuration: configuration)
        controller.delegate = context.coordinator
        return controller
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(handleImages: handleImages, onDismiss: self.onDismiss)
    }
    
    final public class Coordinator: NSObject, PHPickerViewControllerDelegate {
        private let handleImages: ([PHPickerResult]) -> Void
        private let onDismiss: (Int) -> Void
        public init(handleImages: @escaping ([PHPickerResult]) -> Void, onDismiss: @escaping (Int) -> Void) {
            self.handleImages = handleImages
            self.onDismiss = onDismiss
        }
        public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            onDismiss(results.count)
            handleImages(results)
        }
    }
    
}



struct ImagePickerView: UIViewControllerRepresentable {
    
    private var sourceType: UIImagePickerController.SourceType
    private let onImagePicked: (UIImage) -> Void
    private let onDismiss: () -> Void
    
    public init(sourceType: UIImagePickerController.SourceType, onImagePicked: @escaping (UIImage) -> Void, onDismiss: @escaping () -> Void) {
        self.sourceType = sourceType
        self.onImagePicked = onImagePicked
        self.onDismiss = onDismiss
    }
    
    public func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = self.sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    public func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(
            onDismiss: self.onDismiss,
            onImagePicked: self.onImagePicked
        )
    }
    
    final public class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        
        private let onDismiss: () -> Void
        private let onImagePicked: (UIImage) -> Void
        
        init(onDismiss: @escaping () -> Void, onImagePicked: @escaping (UIImage) -> Void) {
            self.onDismiss = onDismiss
            self.onImagePicked = onImagePicked
        }
        
        public func imagePickerController(_ picker: UIImagePickerController,
                                          didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                if picker.sourceType == .camera {
                    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                }
                self.onImagePicked(image)
            }
            self.onDismiss()
        }
        public func imagePickerControllerDidCancel(_: UIImagePickerController) {
            self.onDismiss()
        }
    }
}
