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
//
//    let relativeDateFormatter = RelativeDateTimeFormatter()
//
//    func dateString(for penpal: PenPal) -> String {
//        var result = penpal.lastEventType.datePrefix
//        let formattedDate =
//    }
    
    func dateText(for penpal: PenPal) -> Text {
        if let date = penpal.lastEventDate {
            return Text("\(penpal.lastEventType.datePrefix) ") + Text(date, style: .relative) + Text(" ago")
        } else {
            return Text("")
        }
    }
    
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
                    VStack {
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
                            VStack {
                                Text(penpal.fullName)
                                    .font(.headline)
                                    .fullWidth()
                                if penpal.lastEventDate != nil {
                                    self.dateText(for: penpal)
                                        .font(.caption)
                                        .fullWidth()
                                }
                            }
                        }
                        if let nextEventType = type.nextType {
                            Button(action: {
                                Task {
                                    await penpal.addEvent(ofType: nextEventType)
                                }
                            }) {
                                Text(type.nextTypeButtonText)
                            }
                        }
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
            PenPal(id: "1", givenName: "Ben", familyName: "Cardy", image: nil, _lastEventType: EventType.written.rawValue, lastEventDate: Date()),
            PenPal(id: "2", givenName: "Alex", familyName: "Faber", image: nil, _lastEventType: EventType.written.rawValue, lastEventDate: Date()),
            PenPal(id: "3", givenName: "Madi", familyName: "Van Houten", image: nil, _lastEventType: EventType.written.rawValue, lastEventDate: Date())
        ])
    }
}
