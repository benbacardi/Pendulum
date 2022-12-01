//
//  Picture+Extensions.swift
//  Pendulum
//
//  Created by Ben Cardy on 30/11/2022.
//

import Foundation
import SwiftUI

extension Picture {
    
    static let entityName: String = "Picture"
    
    func image() -> Image? {
        guard let data = self.data, let uiImage = UIImage(data: data) else { return nil }
        return Image(uiImage: uiImage)
    }
    
}
