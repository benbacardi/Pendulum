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
    
    @State private var lastEventType: EventType
    @State private var buttonHeight: CGFloat?
    
    init(penpal: PenPal) {
        self.penpal = penpal
        self._lastEventType = State(wrappedValue: penpal.lastEventType)
        self._penPalViewController = StateObject(wrappedValue: PenPalViewController(penpal: penpal))
    }
    
    @ViewBuilder
    func headerAndButtons() -> some View {
        Group {
            
            PenPalHeader(penpal: penpal)
                .padding(.horizontal)
            
            if lastEventType != .noEvent {
                Text(lastEventType.phrase)
                    .font(.headline)
                    .fullWidth()
                    .padding(.horizontal)
            }
            
            HStack(alignment: .top) {
                ForEach(lastEventType.nextLogicalEventTypes, id: \.self) { eventType in
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
        }
    }
    
    @ViewBuilder
    func dateDivider(for date: Date, withDifference difference: Int, relativeToToday: Bool = false) -> some View {
        let plural = difference > 1 ? "s" : ""
        HStack {
            if relativeToToday {
                if difference == 0 {
                    Text("Today")
                } else {
                    Text("\(difference) day\(plural) ago")
                }
            } else {
                Text("\(difference) day\(plural) before")
            }
            Text("–")
            Text(date, style: .date)
        }
        .font(.caption)
        .foregroundColor(.secondary)
    }
    
    var body: some View {
        // MARK: Action Buttons
        
        VStack(spacing: 10) {
            
            self.headerAndButtons()
            
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
                            let difference = Calendar.current.numberOfDaysBetween(firstEvent.date, and: Date())
                            dateDivider(for: firstEvent.date, withDifference: difference, relativeToToday: true)
                                .padding(.bottom)
                        }
                        
                        ForEach(penPalViewController.eventsWithDifferences, id: \.0) { (event, difference) in
                            if difference > 0 {
                                dateDivider(for: event.date, withDifference: difference)
                                    .padding(.bottom)
                            }
                            EventCell(event: event, lastEventTypeForPenPal: $lastEventType)
                                .padding(.bottom)
                        }
                        #if DEBUG
                        Button(action: {
                            Task {
                                let now = Date()
                                await penpal.addEvent(ofType: .written, forDate: now.addingTimeInterval(-60 * 60 * 24 * 10))
                                await penpal.addEvent(ofType: .sent, forDate: now.addingTimeInterval(-60 * 60 * 24 * 9))
                                await penpal.addEvent(ofType: .theyReceived, forDate: now.addingTimeInterval(-60 * 60 * 24 * 6))
                                await penpal.addEvent(ofType: .inbound, forDate: now.addingTimeInterval((-60 * 60 * 24 * 6) + (60 * 60)))
                                await penpal.addEvent(ofType: .received, forDate: now.addingTimeInterval(-60 * 60 * 24 * 3))
                            }
                        }) {
                            Text("Add Debug Data")
                        }
                        #endif
                    }
                    .padding()
                }
            }
        }
//        .navigationTitle(penpal.name)
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
                AddEventSheet(penpal: penpal, eventType: eventType) { newEvent in
                    if let newEvent = newEvent {
                        withAnimation {
                            self.lastEventType = newEvent.eventType
                        }
                    }
                    self.presentAddEventSheetForType = nil
                }
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
        .navigationBarTitleDisplayMode(.inline)
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