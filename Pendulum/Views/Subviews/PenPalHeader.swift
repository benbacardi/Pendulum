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
    
    var useFullName: Bool = false
    
    var body: some View {
        HStack(alignment: .center) {
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
            VStack(spacing: 0) {
                if useFullName && penpal.wrappedName != penpal.preferredName {
                    Text("“\(penpal.preferredName)”")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fullWidth(alignment: .leading)
                }
                Text(useFullName ? penpal.wrappedName : penpal.preferredName)
                    .font(.largeTitle)
                    .bold()
                    .fullWidth(alignment: .leading)
            }
        }
    }
}
