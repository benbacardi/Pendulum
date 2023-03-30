//
//  EventCell.swift
//  Pendulum
//
//  Created by Ben Cardy on 21/11/2022.
//

import SwiftUI

struct EventCell: View {
    
    @EnvironmentObject var imageViewerController: ImageViewerController
    
    // MARK: Parameters
    let event: Event
    let penpal: PenPal
    
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
    
    @ViewBuilder
    func image(from photo: EventPhoto) -> some View {
        let image = photo.thumbnail() ?? photo.image()
        if let image {
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
    func imageHStack(from photos: [EventPhoto]) -> some View {
        HStack {
            ForEach(photos) { photo in
                Button(action: {
                    withAnimation {
                        imageViewerController.present(self.event.allPhotos(), showing: photo)
                    }
//                    if let image = photo.image() {
//                        imageViewerController.present(image)
//                    }
                }) {
                    self.image(from: photo)
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

                        if !event.allPhotos().isEmpty {
                            ViewThatFits {
                                imageHStack(from: event.allPhotos())
                                ScrollView(.horizontal) {
                                    imageHStack(from: event.allPhotos())
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
                                            VStack(spacing: 2) {
                                                ForEach(event.pens, id: \.self) { pen in
                                                    Text(pen).fullWidth()
                                                }
                                            }
                                        }
                                    }
                                    if let ink = event.ink, !ink.isEmpty {
                                        GridRow {
                                            Image(systemName: "drop")
                                            VStack(spacing: 2) {
                                                ForEach(event.inks, id: \.self) { ink in
                                                    Text(ink).fullWidth()
                                                }
                                            }
                                        }
                                    }
                                    if let paper = event.paper, !paper.isEmpty {
                                        GridRow {
                                            Image(systemName: "doc.plaintext")
                                            VStack(spacing: 2) {
                                                ForEach(event.papers, id: \.self) { paper in
                                                    Text(paper).fullWidth()
                                                }
                                            }
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
