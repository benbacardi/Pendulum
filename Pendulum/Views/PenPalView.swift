//
//  PenPalView.swift
//  Pendulum
//
//  Created by Ben Cardy on 05/11/2022.
//

import SwiftUI
import Contacts

struct PenPalView: View {
    
    // MARK: State
    @StateObject private var penPalViewController: PenPalViewController
    @State private var showingPenPalContactSheet: Bool = false
    @State private var contactsAccessStatus: CNAuthorizationStatus = .notDetermined
    @State private var presentAddEventSheetForType: EventType? = nil
    
    @State private var lastEventType: EventType
    @State private var buttonHeight: CGFloat?
    
    init(penpal: PenPal) {
        self._lastEventType = State(wrappedValue: penpal.lastEventType)
        self._penPalViewController = StateObject(wrappedValue: PenPalViewController(penpal: penpal))
    }
    
    @ViewBuilder
    func headerAndButtons() -> some View {
        Group {
            
            PenPalHeader(penpal: penPalViewController.penpal)
                .padding(.horizontal)
            
            if lastEventType != .noEvent && lastEventType != .archived {
                Text(lastEventType.phrase)
                    .fullWidth()
                    .padding(.horizontal)
            }
            
            HStack(alignment: .top) {
                ForEach(lastEventType.nextLogicalEventTypes, id: \.self) { eventType in
                    Button(action: {
                        self.userTappedAddEvent(ofType: eventType)
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
                            self.userTappedAddEvent(ofType: eventType)
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
                
                Text("It seems you haven't sent or received any letters with \(penPalViewController.penpal.name) yet!")
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
                            EventCell(event: event, penpal: penPalViewController.penpal, lastEventTypeForPenPal: $lastEventType)
                                .padding(.bottom)
                        }
                        #if DEBUG
                        Button(action: {
                            Task {
                                let now = Date()
                                await penPalViewController.penpal.addEvent(ofType: .written, forDate: now.addingTimeInterval(-60 * 60 * 24 * 10))
                                await penPalViewController.penpal.addEvent(ofType: .sent, forDate: now.addingTimeInterval(-60 * 60 * 24 * 9))
                                await penPalViewController.penpal.addEvent(ofType: .theyReceived, forDate: now.addingTimeInterval(-60 * 60 * 24 * 6))
                                await penPalViewController.penpal.addEvent(ofType: .inbound, forDate: now.addingTimeInterval((-60 * 60 * 24 * 6) + (60 * 60)))
                                await penPalViewController.penpal.addEvent(ofType: .received, forDate: now.addingTimeInterval(-60 * 60 * 24 * 3))
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
        .onAppear {
            penPalViewController.start()
            self.contactsAccessStatus = CNContactStore.authorizationStatus(for: .contacts)
        }
        .sheet(isPresented: $showingPenPalContactSheet) {
            PenPalContactSheet(penpal: penPalViewController.penpal)
        }
        .sheet(item: $presentAddEventSheetForType) { eventType in
            AddEventSheet(penpal: penPalViewController.penpal, event: nil, eventType: eventType) { newEvent, newEventType in
                self.lastEventType = newEventType
                self.presentAddEventSheetForType = nil
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
    
    func userTappedAddEvent(ofType eventType: EventType) {
        if eventType.presentFullNotesSheetByDefault && !UserDefaults.shared.enableQuickEntry {
            self.presentAddEventSheetForType = eventType
        } else {
            Task {
                await self.penPalViewController.penpal.addEvent(ofType: eventType)
                let latestEventType = await penPalViewController.penpal.updateLastEventType()
                DispatchQueue.main.async {
                    withAnimation {
                        self.lastEventType = latestEventType
                    }
                }
            }
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
            PenPalView(penpal: PenPal(id: "2", name: "Alex Faber", initials: "AF", image: nil, _lastEventType: EventType.noEvent.rawValue, lastEventDate: Date(), notes: nil))
        }
    }
}
