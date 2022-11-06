//
//  AddEventSheet.swift
//  Pendulum
//
//  Created by Ben Cardy on 06/11/2022.
//

import SwiftUI

struct AddEventSheet: View {
    
    // MARK: Environment
    @Environment(\.presentationMode) var presentationMode
    
    // MARK: Parameters
    let penpal: PenPal
    let eventType: EventType
    
    // MARK: State
    @State private var notes: String = ""
    @State private var pen: String = ""
    @State private var ink: String = ""
    @State private var paper: String = ""
    
    var body: some View {
        Form {
            Section {
                TextField("Notes", text: $notes, axis: .vertical)
            }
            if eventType == .written || eventType == .sent {
                Section {
                    TextField("Pen", text: $pen)
                    TextField("Ink", text: $ink)
                    TextField("Paper", text: $paper)
                }
            }
            Section {
                Button(action: {
                    Task {
                        await penpal.addEvent(ofType: eventType, notes: notes.isEmpty ? nil : notes, pen: pen.isEmpty ? nil : pen, ink: ink.isEmpty ? nil : ink, paper: paper.isEmpty ? nil : paper)
                    }
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Save")
                }
            }
        }
        .navigationTitle("\(eventType.description)!")
    }
}

struct AddEventSheet_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            AddEventSheet(penpal: PenPal(id: "1", givenName: "Alex", familyName: "Faber", image: nil, _lastEventType: nil, lastEventDate: nil), eventType: .written)
        }
    }
}
