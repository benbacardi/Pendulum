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
    
    var body: some View {
        ScrollView {
            Text("Hello")
            Text("\(penPalViewController.events.count) Events")
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
