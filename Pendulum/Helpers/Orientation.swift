//
//  Orientation.swift
//  Elsewhen
//
//  Created by Ben Cardy on 12/10/2021.
//


import UIKit
import Combine

enum DeviceOrientation: String {
    case portrait
    case landscape
}

class OrientationObserver: ObservableObject {
    
    static let shared = OrientationObserver()
    
    @Published var currentOrientation: DeviceOrientation = .portrait
    private var disposables: [AnyCancellable] = []
    
    init() {
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification, object: nil)
            .sink { notification in
                if let device = notification.object as? UIDevice {
                    if device.orientation.isPortrait {
                        self.changeOrientation(to: .portrait)
                    } else {
                        self.changeOrientation(to: .landscape)
                    }
                }
            }
            .store(in: &disposables)
    }
    
    deinit {
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
    }
    
    func changeOrientation(to orientation: DeviceOrientation) {
        currentOrientation = orientation
    }
    
}
