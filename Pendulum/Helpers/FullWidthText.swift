//
//  FullWidthText.swift
//  Pendulum
//
//  Created by Ben Cardy on 05/11/2022.
//

import SwiftUI

struct FullWidthText: ViewModifier {
    
    var alignment: TextAlignment = .leading
    
    func body(content: Content) -> some View {
        content
            .multilineTextAlignment(alignment)
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
    }
}

extension View {
    func fullWidth(alignment: TextAlignment = .leading) -> some View {
        modifier(FullWidthText(alignment: alignment))
    }
}
