//
//  DividerWithText.swift
//  Pendulum
//
//  Created by Ben Cardy on 06/11/2022.
//

import SwiftUI

struct DividerWithText: View {
    
    let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        HStack {
            VStack {
                Divider()
            }
            Text(text)
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
