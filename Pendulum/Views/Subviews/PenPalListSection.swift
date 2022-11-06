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
    
    func dateText(for penpal: PenPal) -> Text {
        if let date = penpal.lastEventDate {
            return Text("\(penpal.lastEventType.datePrefix) \(Calendar.current.verboseNumberOfDaysBetween(date, and: Date()))")
        } else {
            return Text("")
        }
    }
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: type.phraseIcon)
                    .font(.headline)
                Text(type.phrase)
                    .font(.headline)
                    .fullWidth()
            }
            ForEach(penpals) { penpal in
                NavigationLink(destination: PenPalView(penpal: penpal)) {
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
                        }
                        .foregroundColor(.primary)
                    }
                    .contextMenu {
                        ForEach(EventType.actionableCases, id: \.self) { eventType in
                            Button(action: {
                                Task {
                                    await penpal.addEvent(ofType: eventType)
                                }
                            }) {
                                Label(eventType.actionableText, systemImage: eventType.icon)
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
