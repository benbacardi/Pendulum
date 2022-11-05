//
//  PenPalListSection.swift
//  Pendulum
//
//  Created by Ben Cardy on 05/11/2022.
//

import SwiftUI

struct PenPalListSection: View {
    
    // MARK: Parameters
    let type: EventType
    let penpals: [PenPal]
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: type.icon)
                    .font(.headline)
                Text(type.phrase)
                    .font(.headline)
                    .fullWidth()
            }
            ForEach(penpals) { penpal in
                GroupBox {
                    HStack {
                        if let image = penpal.displayImage {
                            image
                                .clipShape(Circle())
                                .frame(width: 40, height: 40)
                        } else {
                            ZStack {
                                Circle()
                                    .fill(.gray)
                                Text(penpal.initials)
                                    .font(.system(.headline, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            .frame(width: 40, height: 40)
                        }
                        Text(penpal.fullName)
                            .font(.headline)
                            .fullWidth()
                    }
                }
            }
        }
        .padding()
    }
}

struct PenPalListSection_Previews: PreviewProvider {
    static var previews: some View {
        PenPalListSection(type: .written, penpals: [
            PenPal(id: "1", givenName: "Ben", familyName: "Cardy", image: nil),
            PenPal(id: "2", givenName: "Alex", familyName: "Faber", image: nil),
            PenPal(id: "3", givenName: "Madi", familyName: "Van Houten", image: nil)
        ])
    }
}
