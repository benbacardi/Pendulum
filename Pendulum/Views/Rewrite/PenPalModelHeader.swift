//
//  PenPalModelHeader.swift
//  Pendulum
//
//  Created by Ben Cardy on 19/04/2024.
//

import SwiftUI

struct PenPalModelHeader: View {
    let penPal: PenPalModel
    @State private var displayImage: Image? = nil
    
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
                    Text(penPal.initials)
                        .font(.system(.headline, design: .rounded))
                        .foregroundColor(.white)
                }
                .frame(width: 40, height: 40)
            }
            Text(penPal.name)
                .font(.largeTitle)
                .bold()
                .fullWidth(alignment: .leading)
        }
        .task {
            displayImage = await penPal.displayImage
        }
    }
}

#Preview {
    PenPalModelHeader(penPal: MockPenPalService.penPals.first!)
}
