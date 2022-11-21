//
//  CDEventCell.swift
//  Pendulum
//
//  Created by Ben Cardy on 21/11/2022.
//

import SwiftUI

struct CDEventCell: View {
    
    // MARK: Parameters
    let event: CDEvent
    let penpal: CDPenPal
    
    // MARK: External State
//    @Binding var lastEventTypeForPenPal: EventType
    
    // MARK: State
    @State private var iconWidth: CGFloat?
    @State private var showDeleteAlert = false
    @State private var showEditEventSheet = false
    
    // MARK: Functions
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
    
    // MARK: Body
    var body: some View {
        HStack(alignment: .top) {
            if !eventIsMyAction {
                eventIcon
            }
            Button(action: {
                self.showEditEventSheet = true
            }) {
                GroupBox {
                    VStack(spacing: 10) {
                        Text(event.type.description)
                            .fullWidth()
                        
                        if event.hasNotes {
                            
                            if let notes = event.notes, !notes.isEmpty {
                                Text(notes)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .fullWidth()
                            }
                            
                            if event.hasAttributes {
                                
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
                    
                }
            }
            .buttonStyle(.plain)
            .contextMenu {
                Button(action: {
                    self.showEditEventSheet = true
                }) {
                    Label("Edit", systemImage: "pencil")
                }
                Divider()
                Button(role: .destructive, action: {
                    self.showDeleteAlert = true
                }) {
                    Label("Delete", systemImage: "trash")
                }
            }
            .confirmationDialog("Are you sure?", isPresented: $showDeleteAlert) {
                Button("Delete Status", role: .destructive) {
                    withAnimation {
                        event.delete()
                    }
                }
            }
            if eventIsMyAction {
                eventIcon
            }
        }
        .sheet(isPresented: $showEditEventSheet) {
            CDAddEventSheet(penpal: penpal, event: event, eventType: event.type) {
                self.showEditEventSheet = false
            }
        }
    }
}

private extension CDEventCell {
    struct IconWidthPreferenceKey: PreferenceKey {
        static let defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = max(value, nextValue())
        }
    }
}
