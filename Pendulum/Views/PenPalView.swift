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
    
    init(penpal: PenPal) {
        self.penpal = penpal
        self._penPalViewController = StateObject(wrappedValue: PenPalViewController(penpal: penpal))
    }
    
    func eventIsMyAction(_ event: Event) -> Bool {
        event.eventType == .written || event.eventType == .sent
    }
    
    func eventIcon(_ event: Event) -> some View {
        ZStack {
            Circle()
                .fill(.gray)
            Image(systemName: event.eventType.icon)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .frame(width: 40, height: 40)
    }
    
    var body: some View {
        // MARK: Action Buttons
        ForEach(EventType.actionableCases, id: \.self) { eventType in
            Button(action: {
                Task {
                    await penpal.addEvent(ofType: eventType)
                }
            }) {
                Label(eventType.actionableText, systemImage: eventType.icon)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .padding(.horizontal)
        }
        // MARK: Timeline
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
                    HStack {
                        if !eventIsMyAction(event) {
                            eventIcon(event)
                        }
                        VStack {
                            Text(event.date, style: .date)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fullWidth(alignment: eventIsMyAction(event) ? .trailing : .leading)
                            Text(event.eventType.description)
                                .fullWidth(alignment: eventIsMyAction(event) ? .trailing : .leading)
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
        .navigationTitle(penpal.fullName)
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
        .toolbar {
            Button(action: {
                self.showingPenPalContactSheet = true
            }){
                Label("Pen Pal Addresses", systemImage:"person.crop.circle")
            }
            .disabled(contactsAccessStatus != .authorized)
        }
    }
}

struct PenPalView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            PenPalView(penpal: PenPal(id: "2", givenName: "Alex", familyName: "Faber", image: nil, _lastEventType: EventType.written.rawValue, lastEventDate: Date()))
        }
    }
}
