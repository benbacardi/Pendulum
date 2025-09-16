//
//  ImageGalleryOverlay.swift
//  Pendulum
//
//  Created by Ben Cardy on 29/03/2023.
//

import SwiftUI
import QuickLook

struct PreviewController: UIViewControllerRepresentable {
    let imageViewerController: ImageViewerController
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        controller.delegate = context.coordinator
        controller.navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close, target: context.coordinator,
            action: #selector(context.coordinator.dismiss)
        )
        if let showParticularImage = self.imageViewerController.image {
            controller.currentPreviewItemIndex = self.imageViewerController.images.firstIndex(of: showParticularImage) ?? 1
        }
        let navigationController = UINavigationController(rootViewController: controller)
        return navigationController
    }
    
    func makeCoordinator() -> QLPreviewCoordinator {
        return QLPreviewCoordinator(parent: self)
    }
    
    func updateUIViewController(
        _ uiViewController: UINavigationController, context: Context) {}
}

class QLPreviewCoordinator: NSObject, QLPreviewControllerDataSource {
    let parent: PreviewController
    
    init(parent: PreviewController) {
        self.parent = parent
    }
    
    func numberOfPreviewItems(
        in controller: QLPreviewController
    ) -> Int {
        return self.parent.imageViewerController.images.count
    }
    
    func previewController(
        _ controller: QLPreviewController,
        previewItemAt index: Int
    ) -> QLPreviewItem {
        return self.parent.imageViewerController.urls[index]
    }
    
    @objc func dismiss() {
        self.parent.imageViewerController.dismiss()
    }
    
}

extension QLPreviewCoordinator: QLPreviewControllerDelegate {
    func previewController(_ controller: QLPreviewController, editingModeFor previewItem: QLPreviewItem) -> QLPreviewItemEditingMode {
        return .disabled }
}

struct ImageGalleryOverlay: View {
    
    @EnvironmentObject var imageViewerController: ImageViewerController
    
    var body: some View {
        if !imageViewerController.images.isEmpty {
            PreviewController(imageViewerController: imageViewerController)
                .edgesIgnoringSafeArea(.vertical)
                .statusBarHidden()
        } else {
            EmptyView()
        }
    }
}

struct ImageGalleryOverlay_Previews: PreviewProvider {
    static var previews: some View {
        ImageGalleryOverlay()
            .environmentObject(ImageViewerController())
    }
}
