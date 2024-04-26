//
//  PenPalModelCell.swift
//  Pendulum
//
//  Created by Ben Cardy on 22/04/2024.
//

import SwiftUI

struct PenPalModelCell: View {
    
    let penPal: PenPalModel
    var subText: String? = nil
    
    @State private var displayImage: Image? = nil
    
    var body: some View {
        VStack {
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
                    .task { displayImage = await penPal.displayImage }
                }
                VStack {
                    Text(penPal.name)
                        .font(.headline)
                        .fullWidth()
                    if let subText = subText {
                        Text(subText)
                            .font(.caption)
                            .fullWidth()
                    } else {
                        if let lastEventDate = penPal.lastEventDate, let lastEventLetterType = penPal.lastEventLetterType {
                            Text("\(penPal.lastEventType.datePrefix(for: lastEventLetterType)) \(Calendar.current.verboseNumberOfDaysBetween(lastEventDate, and: Date()))")
                                .font(.caption)
                                .fullWidth()
                        }
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Color.accentColor, lineWidth: 0)
                .background {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color(uiColor: .secondarySystemBackground))
                }
        }
        .opacity(penPal.isArchived ? 0.5 : 1)
    }
}

#Preview {
    VStack {
        PenPalModelCell(penPal: MockPenPalService.penPals.first!)
        PenPalModelCell(penPal: MockPenPalService.penPals[1])
    }
}
