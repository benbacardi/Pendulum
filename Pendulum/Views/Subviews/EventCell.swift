//
//  EventCell.swift
//  Pendulum
//
//  Created by Ben Cardy on 21/11/2022.
//

import SwiftUI

struct EventCell: View {
    
    @Environment(\.openURL) var openURL
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject var imageViewerController: ImageViewerController
    
    // MARK: Parameters
    let event: Event
    let penpal: PenPal
    
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
                    .padding([.horizontal, .top])
                    .padding(.bottom, event.allPhotos().isEmpty ? 5 : 0)

                    if !event.allPhotos().isEmpty {
                        ViewThatFits(in: .horizontal) {
                            imageHStack(from: event.allPhotos())
                                .padding(.horizontal)
                            ScrollView(.horizontal, showsIndicators: false) {
                                imageHStack(from: event.allPhotos())
                                    .padding(.horizontal)
                            }
                        }
                        
                        if event.hasNotes {
                            Rectangle()
                                .fill(.clear)
                                .frame(height: 1)
                        }
                        
                    }
                    
                    VStack {
                        
                        if event.hasNotes {
                            
                            if let notes = event.notes, !notes.isEmpty {
                                Text(notes)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .fullWidth()
                                    .padding(.bottom, event.hasAttributes ? 5 : 0)
                                
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
            }
            .buttonStyle(.plain)
            .animation(.default, value: penpal)
            .contextMenu {
                if !(event.trackingReference?.isEmpty ?? true) {
                    Button(action: {
                        openURL(URL(string: "https://t.17track.net/en#nums=\(event.trackingReference ?? "")")!)
                    }) {
                        Label("Track \(event.letterType.properNoun) on 17track.net", systemImage: "mappin.and.ellipse")
                    }
                    Button(action: {
                        if let trackingReference = event.trackingReference {
                            UIPasteboard.general.string = trackingReference
                        }
                    }) {
                        Label("Copy Tracking Reference", systemImage: "smallcircle.filled.circle")
                    }
                }
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
                        event.delete(in: moc)
                    }
                }
            }
            if eventIsMyAction {
                eventIcon
            }
        }
        .sheet(isPresented: $showEditEventSheet) {
            AddEventSheet(penpal: penpal, event: event) {
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
