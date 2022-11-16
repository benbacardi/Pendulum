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
                    Text(penpal.initials)
                        .font(.system(.headline, design: .rounded))
                        .foregroundColor(.white)
                }
                .frame(width: 40, height: 40)
            }
            Text(penpal.name)
                .font(.largeTitle)
                .bold()
                .fullWidth(alignment: .leading)
        }
    }
}

struct PenPalHeader_Previews: PreviewProvider {
    static var previews: some View {
        PenPalHeader(penpal: PenPal(id: UUID().uuidString, name: "Madi Van Houten", initials: "MV", image: nil, _lastEventType: EventType.written.rawValue, lastEventDate: Date(), notes: nil, lastUpdated: Date(), dateDeleted: nil, cloudKitID: nil))
    }
}
