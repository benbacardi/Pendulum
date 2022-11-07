//
//  PenPalView.swift
//  Pendulum
//
//  Created by Ben Cardy on 05/11/2022.
//

import SwiftUI
import Contacts

struct PenPalView: View {
    
    // MARK: Parameters
    let penpal: PenPal
    
    // MARK: State
    @StateObject private var penPalViewController: PenPalViewController
    @State private var showingPenPalContactSheet: Bool = false
    @State private var contactsAccessStatus: CNAuthorizationStatus = .notDetermined
    @State private var presentAddEventSheetForType: EventType? = nil
    
    @State private var buttonHeight: CGFloat?
        
    init(penpal: PenPal) {
        self.penpal = penpal
        self._penPalViewController = StateObject(wrappedValue: PenPalViewController(penpal: penpal))
    }
    
    func eventIsMyAction(_ event: Event) -> Bool {
        event.eventType == .written || event.eventType == .sent
    }
    
    func eventIcon(_ event: Event) -> some View {
        Image(systemName: event.eventType.icon)
            .bold()
            .padding(.top, 15)
//        ZStack {
//            Circle()
//                .fill(.gray)
//            Image(systemName: event.eventType.icon)
//                .fontWeight(.bold)
//                .foregroundColor(.white)
//        }
//        .frame(width: 40, height: 40)
    }
    
    var body: some View {
        // MARK: Action Buttons
        
        VStack {
            
            HStack(alignment: .top) {
                ForEach(penpal.lastEventType.nextLogicalEventTypes, id: \.self) { eventType in
                    Button(action: {
                        presentAddEventSheetForType = eventType
                    }) {
                        Label(eventType.actionableTextShort, systemImage: eventType.icon)
                            .fullWidth(alignment: .center)
                            .font(.headline)
                            .background(GeometryReader { geometry in
                                Color.clear.preference(key: ButtonHeightPreferenceKey.self, value: geometry.size.height)
                            })
                    }
                    .tint(eventType.color)
                    .buttonStyle(.borderedProminent)
                }
                Menu {
                    ForEach(EventType.actionableCases, id: \.self) { eventType in
                        Button(action: {
                            presentAddEventSheetForType = eventType
                        }) {
                            Label(eventType.actionableText, systemImage: eventType.icon)
                        }
                    }
                } label: {
                    Label("More actions", systemImage: "ellipsis")
                        .labelStyle(.iconOnly)
                        .frame(height: buttonHeight)
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)
            
            // MARK: Timeline
            if penPalViewController.events.isEmpty {
                
                Spacer()
                
                if let image = UIImage(named: "undraw_letter_re_8m03") {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 200)
                }
                
                Text("It seems you haven't sent or received any letters with \(penpal.name) yet!")
                    .fullWidth(alignment: .center)
                    .padding()
                    .padding(.top)
                
                Spacer()
                
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        
                        if let firstEvent = penPalViewController.events.first {
                            let daysAgo = Calendar.current.numberOfDaysBetween(firstEvent.date, and: Date())
                            Group {
                                if daysAgo == 0 {
                                    DividerWithText("Today")
                                } else {
                                    DividerWithText("\(daysAgo) day\(daysAgo > 1 ? "s" : "") ago")
                                }
                            }
                            .padding(.bottom)
                        }
                        
                        ForEach(penPalViewController.eventsWithDifferences, id: \.0) { (event, difference) in
                            HStack(alignment: .top) {
                                if !eventIsMyAction(event) {
                                    eventIcon(event)
                                }
                                GroupBox {
                                    VStack {
                                        //                                Text(event.date, style: .date)
                                        //                                    .font(.caption)
                                        //                                    .foregroundColor(.secondary)
                                        //                                    .fullWidth(alignment: eventIsMyAction(event) ? .trailing : .leading)
                                        Text(event.eventType.description)
                                            .fullWidth()//alignment: eventIsMyAction(event) ? .trailing : .leading)
                                    }
                                    if event.hasNotes {
                                        VStack(alignment: .leading, spacing: 2) {
                                            if let notes = event.notes, !notes.isEmpty {
                                                Text(notes)
                                            }
                                            if let pen = event.pen, !pen.isEmpty {
                                                Label(pen, systemImage: "pencil")
                                            }
                                            if let ink = event.ink, !ink.isEmpty {
                                                Label(ink, systemImage: "drop")
                                            }
                                            if let paper = event.paper, !paper.isEmpty {
                                                Label(paper, systemImage: "doc.plaintext")
                                            }
                                        }
                                        .fullWidth()
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.top, 1)
                                    }
                                    
                                }
                                if eventIsMyAction(event) {
                                    eventIcon(event)
                                }
                            }
                            .padding(.bottom)
                            if difference > 0 {
                                DividerWithText("\(difference) day\(difference > 1 ? "s" : "") before")
                                    .padding(.bottom)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(penpal.name)
        .onAppear {
            penPalViewController.start()
            self.contactsAccessStatus = CNContactStore.authorizationStatus(for: .contacts)
        }
        .sheet(isPresented: $showingPenPalContactSheet) {
            NavigationStack {
                PenPalContactSheet(penpal: penpal)
                    .toolbar {
                        Button(action: {
                            self.showingPenPalContactSheet = false
                        }) {
                            Text("Done")
                        }
                    }
            }
        }
        .sheet(item: $presentAddEventSheetForType) { eventType in
            NavigationStack {
                AddEventSheet(penpal: penpal, eventType: eventType)
            }
        }
        .toolbar {
            Button(action: {
                self.showingPenPalContactSheet = true
            }){
                Label("Pen Pal Addresses", systemImage:"person.crop.circle")
            }
            .disabled(contactsAccessStatus != .authorized)
        }
        .onPreferenceChange(ButtonHeightPreferenceKey.self) {
            self.buttonHeight = $0
        }
    }
}

private extension PenPalView {
    struct ButtonHeightPreferenceKey: PreferenceKey {
        static let defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = max(value, nextValue())
        }
    }
}

struct PenPalView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            PenPalView(penpal: PenPal(id: "2", name: "Alex Faber", initials: "AF", image: nil, _lastEventType: EventType.noEvent.rawValue, lastEventDate: Date()))
        }
    }
}
