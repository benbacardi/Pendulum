//
//  LabelStyle.swift
//  Pendulum
//
//  Created by Ben Cardy on 16/09/2025.
//

import SwiftUI

struct LabelStyleIconOnlyOn26: ViewModifier {
    
    var labelStyle: some LabelStyle {
        if #available(iOS 26, *) {
            return IconOnlyLabelStyle()
        } else {
            return TitleOnlyLabelStyle()
        }
    }
    
    func body(content: Content) -> some View {
        content.labelStyle(labelStyle)
    }
}

extension View {
    func labelStyleIconOnlyOn26() -> some View {
        self.modifier(LabelStyleIconOnlyOn26())
    }
}
