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
    
    // MARK: External State
    @Binding var iconWidth: CGFloat
    @Binding var presentAddEventSheetForType: PresentAddEventSheet?
    
    // MARK: Internal State
    @State private var currentPenPal: PenPal? = nil
    @State private var showDeleteAlert = false
    
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
                ZStack {
                    Rectangle()
                        .fill(type.color)
                        .frame(width: iconWidth * 1.2, height: iconWidth * 1.2)
                        .cornerRadius(100, corners: .allCorners)
                    Image(systemName: type.phraseIcon)
                        .font(.caption)
                        .bold()
                        .foregroundColor(.white)
                        .background(GeometryReader { geo in
                            Color.clear.preference(key: PenPalListIconWidthPreferenceKey.self, value: geo.size.width)
                        })
                }
                Text(type.phrase)
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
                                    Text(penpal.name)
                                        .font(.headline)
                                        .fullWidth()
                                    if penpal.lastEventDate != nil && penpal.lastEventType != .archived {
                                        self.dateText(for: penpal)
                                            .font(.caption)
                                            .fullWidth()
                                    }
                                }
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .foregroundColor(.primary)
                    }
                    .contextMenu {
                        ForEach(EventType.actionableCases, id: \.self) { eventType in
                            Button(action: {
                                if eventType.presentFullNotesSheetByDefault && !UserDefaults.shared.enableQuickEntry {
                                    self.presentAddEventSheetForType = PresentAddEventSheet(penpal: penpal, eventType: eventType)
                                } else {
                                    Task {
                                        await penpal.addEvent(ofType: eventType)
                                    }
                                }
                            }) {
                                Label(eventType.actionableText, systemImage: eventType.icon)
                            }
                        }
                        Divider()
                        Button(action: {
                            Task {
                                if penpal.lastEventType != .archived {
                                    await penpal.archive()
                                } else {
                                    await penpal.updateLastEventType()
                                }
                            }
                        }) {
                            if penpal.lastEventType != .archived {
                                Label("Archive", systemImage: "archivebox")
                            } else {
                                Label("Unarchive", systemImage: "archivebox")
                            }
                        }
                        Button(role: .destructive, action: {
                            self.currentPenPal = penpal
                            self.showDeleteAlert = true
                        }) {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .confirmationDialog("Are you sure?", isPresented: $showDeleteAlert, titleVisibility: .visible, presenting: currentPenPal) { penpal in
                        Button("Delete \(penpal.name)", role: .destructive) {
                            Task {
                                await penpal.delete()
                            }
                        }
                    }
                }
            }
        }
        .padding([.horizontal, .top])
        .opacity(type == .archived ? 0.5 : 1)
    }
    
}

struct PenPalListSection_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            PenPalListSection(type: .written, penpals: [
                PenPal(id: "1", name: "Ben Cardy", initials: "BC", image: nil, _lastEventType: EventType.written.rawValue, lastEventDate: Date(), notes: nil),
                PenPal(id: "2", name: "Alex Faber", initials: "AF", image: nil, _lastEventType: EventType.written.rawValue, lastEventDate: Date(), notes: nil),
                PenPal(id: "3", name: "Madi Van Houten", initials: "MV", image: nil, _lastEventType: EventType.written.rawValue, lastEventDate: Date(), notes: nil)
            ], iconWidth: .constant(20), presentAddEventSheetForType: .constant(nil))
            PenPalListSection(type: .inbound, penpals: [
                PenPal(id: "1", name: "Ben Cardy", initials: "BC", image: nil, _lastEventType: EventType.written.rawValue, lastEventDate: Date(), notes: nil),
                PenPal(id: "2", name: "Alex Faber", initials: "AF", image: nil, _lastEventType: EventType.written.rawValue, lastEventDate: Date(), notes: nil)
            ], iconWidth: .constant(20), presentAddEventSheetForType: .constant(nil))
        }
    }
}
