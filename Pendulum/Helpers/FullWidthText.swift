//
//  FullWidthText.swift
//  Pendulum
//
//  Created by Ben Cardy on 05/11/2022.
//

import SwiftUI

struct FullWidthText: ViewModifier {
    
    var alignment: TextAlignment = .leading
    
    var frameAlignment: Alignment {
        switch alignment {
        case .leading:
            return .leading
        case .trailing:
            return .trailing
        case .center:
            return .center
        }
    }
    
    func body(content: Content) -> some View {
        content
            .multilineTextAlignment(alignment)
            .frame(minWidth: 0, maxWidth: .infinity, alignment: frameAlignment)
    }
}

extension View {
    func fullWidth(alignment: TextAlignment = .leading) -> some View {
        modifier(FullWidthText(alignment: alignment))
    }
}
