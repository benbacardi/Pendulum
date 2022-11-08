//
//  EventCell.swift
//  Pendulum
//
//  Created by Ben Cardy on 08/11/2022.
//

import SwiftUI

struct EventCell: View {
    
    // MARK: Parameters
    let event: Event
    
    // MARK: External State
    @Binding var lastEventTypeForPenPal: EventType
    
    // MARK: State
    @State private var iconWidth: CGFloat?
    @State private var showDeleteAlert = false
    
    // MARK: Functions
    var eventIsMyAction: Bool {
        event.eventType == .written || event.eventType == .sent
    }
    
    @ViewBuilder
    var eventIcon: some View {
        ZStack {
            Circle()
                .fill(event.eventType.color)
            Image(systemName: event.eventType.icon)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .frame(width: 30, height: 30)
        .padding(.top, 10)
    }
    
    // MARK: Body
    var body: some View {
        HStack(alignment: .top) {
            if !eventIsMyAction {
                eventIcon
            }
            GroupBox {
                VStack(spacing: 10) {
                Text(event.eventType.description)
                    .fullWidth()
                
                    if event.hasNotes {
                        
                        if let notes = event.notes, !notes.isEmpty {
                            Text(notes)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fullWidth()
                        }
                        
                        Grid(alignment: .topLeading, verticalSpacing: 4) {
                            if let pen = event.pen, !pen.isEmpty {
                                GridRow {
                                    Image(systemName: "pencil")
                                    Text(pen)
                                        .fullWidth()
                                }
                            }
                            if let ink = event.ink, !ink.isEmpty {
                                GridRow {
                                    Image(systemName: "drop")
                                    Text(ink)
                                        .fullWidth()
                                }
                            }
                            if let paper = event.paper, !paper.isEmpty {
                                GridRow {
                                    Image(systemName: "doc.plaintext")
                                    Text(paper)
                                        .fullWidth()
                                }
                            }
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fullWidth()
                        
                    }
                    
                }
                
            }
            .contextMenu {
                Button(role: .destructive, action: {
                    self.showDeleteAlert = true
                }) {
                    Label("Delete", systemImage: "trash")
                }
            }
            .confirmationDialog("Are you sure?", isPresented: $showDeleteAlert) {
                Button("Delete Status", role: .destructive) {
                    Task {
                        self.lastEventTypeForPenPal = await event.delete()
                    }
                }
            }
            if eventIsMyAction {
                eventIcon
            }
        }
    }
}

private extension EventCell {
    struct IconWidthPreferenceKey: PreferenceKey {
        static let defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = max(value, nextValue())
        }
    }
}

struct EventCell_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            EventCell(event: Event(id: nil, _type: 99, date: Date(), penpalID: "123", notes: "Relay FM / St Jude challenge coin, and a LEGO Benny", pen: "TWSBI Eco Clear M", ink: "TWSBI 1791 Orange", paper: "Clairfontaine Triomphe A5 Plain"), lastEventTypeForPenPal: .constant(.written))
                .padding(.horizontal)
            EventCell(event: Event(id: nil, _type: 1, date: Date(), penpalID: "123", notes: "Relay FM / St Jude challenge coin, and a LEGO Benny", pen: nil, ink: "", paper: "Paper"), lastEventTypeForPenPal: .constant(.written))
                .padding(.horizontal)
            EventCell(event: Event(id: nil, _type: 2, date: Date(), penpalID: "123", notes: "Relay FM / St Jude challenge coin, and a LEGO Benny", pen: nil, ink: "", paper: nil), lastEventTypeForPenPal: .constant(.written))
                .padding(.horizontal)
            EventCell(event: Event(id: nil, _type: 3, date: Date(), penpalID: "123", notes: nil, pen: nil, ink: "", paper: "A really long paper name like something ridiculous really silly"), lastEventTypeForPenPal: .constant(.written))
                .padding(.horizontal)
            EventCell(event: Event(id: nil, _type: 4, date: Date(), penpalID: "123", notes: nil, pen: nil, ink: "", paper: nil), lastEventTypeForPenPal: .constant(.written))
                .padding(.horizontal)
            EventCell(event: Event(id: nil, _type: 5, date: Date(), penpalID: "123", notes: nil, pen: nil, ink: "", paper: nil), lastEventTypeForPenPal: .constant(.written))
                .padding(.horizontal)
        }
    }
}
