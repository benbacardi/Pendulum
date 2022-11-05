//
//  PenPalView.swift
//  Pendulum
//
//  Created by Ben Cardy on 05/11/2022.
//

import SwiftUI

struct PenPalView: View {
    
    // MARK: Parameters
    let penpal: PenPal
    
    // MARK: State
    @StateObject private var penPalViewController: PenPalViewController
    
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
        ScrollView {
            VStack(spacing: 0) {
                Divider()
                    .padding(.bottom)
                ForEach(penPalViewController.events, id: \.id) { event in
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
                    Divider()
                        .padding(.vertical)
                }
            }
            .padding()
        }
        .navigationTitle(penpal.fullName)
        .onAppear {
            penPalViewController.start()
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
