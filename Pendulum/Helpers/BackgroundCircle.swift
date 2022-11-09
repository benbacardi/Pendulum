//
//  BackgroundCircle.swift
//  Pendulum
//
//  Created by Ben Cardy on 09/11/2022.
//

import Foundation
import SwiftUI

struct BackgroundCircle: ViewModifier {
    
    @State var contentSize: CGFloat = .zero
    
    let color: Color
    let circleSizeMultiplier: CGFloat
    let minimumSize: CGFloat
    
    var backgroundSize: CGFloat {
        max(contentSize * circleSizeMultiplier, minimumSize)
    }
    
    func body(content: Content) -> some View {
        ZStack(alignment: .center) {
            Circle()
                .fill(color)
                .frame(width: backgroundSize, height: backgroundSize)
            content
                .foregroundColor(.white)
                .background(GeometryReader { geo in
                    Color.clear.preference(key: CircleSizePreferenceKey.self, value: geo.size)
                })
        }
        .onPreferenceChange(CircleSizePreferenceKey.self) {
            contentSize = max($0.width, $0.height)
        }
    }
}

fileprivate struct CircleSizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {}
}

extension View {
    func backgroundCircle(color: Color = .gray, multiplier: CGFloat = 1.5, minimumSize: CGFloat = 20) -> some View {
        modifier(BackgroundCircle(color: color, circleSizeMultiplier: multiplier, minimumSize: minimumSize))
    }
}
