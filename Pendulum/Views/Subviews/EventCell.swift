//
//  EventCell.swift
//  Pendulum
//
//  Created by Ben Cardy on 21/11/2022.
//

import SwiftUI

struct EventCell: View {
    
    // MARK: Parameters
    let event: Event
    let penpal: PenPal
    
    // MARK: External State
//    @Binding var lastEventTypeForPenPal: EventType
    @Binding var showImageViewer: Bool
    @Binding var previewImage: Image?
    
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
    
    @ViewBuilder
    func image(from picture: Picture) -> some View {
        if let image = picture.image() {
            image
                .resizable()
                .scaledToFill()
                .frame(width: 60, height: 60)
                .cornerRadius(5)
        } else {
            EmptyView()
        }
    }
    
    @ViewBuilder
    func imageHStack(from pictures: [Picture]) -> some View {
        HStack {
            ForEach(pictures) { picture in
                Button(action: {
                    if let image = picture.image() {
                        self.previewImage = image
                        self.showImageViewer = true
                    }
                }) {
                    self.image(from: picture)
                }
            }
            Spacer()
        }
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
                        
                        HStack {
                            Text(event.type.description(for: event.letterType))
                                .fullWidth()
                            if event.ignore {
                                Spacer()
                                ZStack {
                                    Image(systemName: "arrowshape.turn.up.left")
                                        .font(.caption)
                                    Image(systemName: "line.diagonal")
                                }
                                .foregroundColor(.secondary)
                            }
                        }
                        
                        if !event.allPictures().isEmpty {
                            ViewThatFits {
                                imageHStack(from: event.allPictures())
                                ScrollView(.horizontal) {
                                    imageHStack(from: event.allPictures())
                                }
                            }
                        }
                        
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
            .animation(.default, value: penpal)
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
            AddEventSheet(penpal: penpal, event: event, eventType: event.type) {
                self.showEditEventSheet = false
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
