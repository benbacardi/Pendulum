//
//  PenPalHeader.swift
//  Pendulum
//
//  Created by Ben Cardy on 07/11/2022.
//

import SwiftUI

struct PenPalHeader: View {
    
    @ObservedObject var penpal: PenPal
    @State private var displayImage: Image?
    
    var body: some View {
        HStack {
            if let displayImage {
                displayImage
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
                .task {
                    self.displayImage = await penpal.displayImage
                }
            }
            Text(penpal.wrappedName)
                .font(.largeTitle)
                .bold()
                .fullWidth(alignment: .leading)
        }
    }
}
