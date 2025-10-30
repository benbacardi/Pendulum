//
//  Backport.swift
//  Pendulum
//
//  Created by Ben Cardy on 28/10/2025.
//  https://davedelong.com/blog/2021/10/09/simplifying-backwards-compatibility-in-swift/
//

import SwiftUI

public struct Backport<Content> {
    public let content: Content

    public init(_ content: Content) {
        self.content = content
    }
}

extension View {
    var backport: Backport<Self> { Backport(self) }
}

extension Backport where Content: View {
    
    enum Glass {
        case regular
        case clear
        case tint(_: Color)
        
        @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, *)
        var glass: SwiftUI.Glass {
            switch self {
            case .clear:
                return .clear
            case .tint(let color):
                return .regular.tint(color)
            default:
                return .regular
            }
        }
        
    }
    
    @ViewBuilder func glassEffect(_ glass: Glass = .regular, cornerRadius: CGFloat? = nil) -> some View {
        if #available(iOS 26, *) {
            if let cornerRadius {
                content.glassEffect(glass.glass, in: .rect(cornerRadius: cornerRadius))
            } else {
                content.glassEffect(glass.glass, in: DefaultGlassEffectShape())
            }
        } else {
            GroupBox {
                content
            }
            .groupBoxStyle(ExtendedGroupBoxStyle(cornerRadius: cornerRadius ?? 16, includePadding: false))
        }
    }
    
}
