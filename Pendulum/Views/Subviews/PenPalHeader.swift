//
//  PenPalHeader.swift
//  Pendulum
//
//  Created by Ben Cardy on 07/11/2022.
//

import SwiftUI

struct PenPalHeader: View {
    
    let penpal: PenPal
    
    var body: some View {
        HStack {
            if let image = penpal.displayImage {
                image
                    .clipShape(Circle())
                    .frame(width: 40, height: 40)
            } else {
                ZStack {
                    Circle()
                        .fill(.gray)
                    Text(penpal.wrappedInitials)
                        .font(.system(.headline, design: .rounded))
                        .foregroundColor(.white)
                }
                .frame(width: 40, height: 40)
            }
            Text(penpal.wrappedName)
                .font(.largeTitle)
                .bold()
                .fullWidth(alignment: .leading)
        }
    }
}
