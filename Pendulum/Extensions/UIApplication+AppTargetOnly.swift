//
//  UIApplication+AppTargetOnly.swift
//  Pendulum
//
//  Created by Ben Cardy on 01/08/2023.
//

import Foundation
import UIKit

extension UIApplication {
    
    static var systemSettingsURL: URL? {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return nil }
        guard UIApplication.shared.canOpenURL(url) else { return nil }
        return url
    }
    
}
