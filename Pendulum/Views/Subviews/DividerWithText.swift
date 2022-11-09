//
//  DividerWithText.swift
//  Pendulum
//
//  Created by Ben Cardy on 06/11/2022.
//

import SwiftUI

struct DividerWithText: View {
    
    let text: String
    let subText: Text?
    let showDivider: Bool
    
    init(_ text: String, subText: Text? = nil, showDivider: Bool = false) {
        self.text = text
        self.subText = subText
        self.showDivider = showDivider
    }
    
    var body: some View {
        HStack {
            if showDivider {
                VStack {
                    Divider()
                }
            }
            VStack {
                Text(text)
                if let subText = subText {
                    subText
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)
            if showDivider {
                VStack {
                    Divider()
                }
            }
        }
    }
}

struct DividerWithText_Previews: PreviewProvider {
    static var previews: some View {
        DividerWithText("foo")
    }
}
