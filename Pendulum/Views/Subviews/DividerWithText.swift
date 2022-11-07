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
    
    init(_ text: String, subText: Text? = nil) {
        self.text = text
        self.subText = subText
    }
    
    var body: some View {
        HStack {
            VStack {
                Divider()
            }
            VStack {
                Text(text)
                if let subText = subText {
                    subText
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)
            VStack {
                Divider()
            }
        }
    }
}

struct DividerWithText_Previews: PreviewProvider {
    static var previews: some View {
        DividerWithText("foo")
    }
}
