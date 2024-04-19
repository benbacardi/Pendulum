//
//  EventModelCell.swift
//  Pendulum
//
//  Created by Ben Cardy on 18/04/2024.
//

import SwiftUI

struct EventModelCell: View {
    @Environment(\.openURL) var openURL
    @Environment(\.colorScheme) var colorScheme
    
    let event: EventModel
    let onDelete: (EventModel) -> Void
    
    var eventIsMyAction: Bool {
        event.type == .written || event.type == .sent
    }
    
    @ViewBuilder
    var eventIcon: some View {
        ZStack {
            Circle()
                .fill(event.type.color)
            Image(systemName: event.type.icon)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .frame(width: 30, height: 30)
        .padding(.top, 10)
    }
    
    var body: some View {
        HStack(alignment: .top) {
            if !eventIsMyAction {
                eventIcon
            }
            GroupBox {
                HStack {
                    Text(event.type.description(for: event.letterType))
                        .fullWidth()
                    if event.noFurtherActions || event.noResponseNeeded {
                        Spacer()
                        ZStack {
                            if event.noFurtherActions {
                                Image(systemName: "arrow.down.to.line")
                                    .font(.caption)
                            } else {
                                Image(systemName: "arrowshape.turn.up.left")
                                    .font(.caption)
                                Image(systemName: "line.diagonal")
                                
                            }
                        }
                        .foregroundColor(.secondary)
                    }
                }
                .padding([.horizontal, .top])
                .padding(.bottom, event.hasAttributes ? 5 : 0)
                
                VStack {
                    if event.hasNotesOrAttributes {
                        if let notes = event.notes {
                            Text(notes)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fullWidth()
                                .padding(.bottom, event.hasAttributes ? 5 : 0)
                        }
                        if event.hasAttributes {
                            Grid(alignment: .topLeading, verticalSpacing: 4) {
                                if !event.pens.isEmpty {
                                    GridRow {
                                        Image(systemName: "pencil")
                                            .padding(.top, 2)
                                        VStack(spacing: 2) {
                                            ForEach(event.pens, id: \.self) { pen in
                                                Text(pen).fullWidth()
                                            }
                                        }
                                    }
                                }
                                if !event.ink.isEmpty {
                                    GridRow {
                                        Image(systemName: "drop")
                                        VStack(spacing: 2) {
                                            ForEach(event.ink, id: \.self) { ink in
                                                Text(ink).fullWidth()
                                            }
                                        }
                                    }
                                }
                                if !event.paper.isEmpty {
                                    GridRow {
                                        Image(systemName: "doc.plaintext")
                                        VStack(spacing: 2) {
                                            ForEach(event.paper, id: \.self) { paper in
                                                Text(paper).fullWidth()
                                            }
                                        }
                                    }
                                }
                                
                                if let trackingReference = event.trackingReference, !trackingReference.isEmpty {
                                    GridRow {
                                        Image(systemName: "smallcircle.filled.circle")
                                        Text(trackingReference)
                                    }
                                    .padding(.top, event.hasStationery ? 5 : 0)
                                }
                                
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fullWidth()
                        }
                    }
                }
                .padding([.horizontal, .bottom])
            }
            .contextMenu {
                if let trackingReference = event.trackingReference {
                    Button(action: {
                        if let url = URL(string: "https://t.17track.net/en#nums=\(trackingReference)") {
                            openURL(url)
                        }
                    }) {
                        Label("Track \(event.letterType.properNoun) on 17track.net", systemImage: "mappin.and.ellipse")
                    }
                }
                Button(action: {
                    print("Edit: TKTK")
                }) {
                    Label("Edit", systemImage: "pencil")
                }
                Divider()
                Button(role: .destructive, action: {
                    onDelete(event)
                }) {
                    Label("Delete", systemImage: "trash")
                }
            }
            if eventIsMyAction {
                eventIcon
            }
        }
        .groupBoxStyle(ExtendedGroupBoxStyle(background: colorScheme == .dark ? Color(.secondarySystemGroupedBackground) : Color(.systemGroupedBackground), includePadding: false))
    }
}

#Preview {
    EventModelCell(event: MockPenPalService.events.first!) { eventModel in
    }
}
