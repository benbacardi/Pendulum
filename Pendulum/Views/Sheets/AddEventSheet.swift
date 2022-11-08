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
    let penpal: PenPal
    let eventType: EventType
    let done: (Event?) -> ()
    
    // MARK: State
    @State private var notes: String = ""
    @State private var pen: String = ""
    @State private var ink: String = ""
    @State private var paper: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 4) {
                Image(systemName: eventType.icon)
                    .font(.largeTitle)
                Text("\(eventType.description)!")
                    .font(.largeTitle)
                    .bold()
                    .fullWidth(alignment: .center)
            }
            .foregroundColor(.white)
            .padding()
            .padding(.vertical)
            .background(eventType.color)
            Form {
                Section {
                    TextField("Notes", text: $notes, axis: .vertical)
                }
                if eventType == .written || eventType == .sent {
                    Section {
                        HStack {
                            Image(systemName: "pencil")
                                .foregroundColor(.secondary)
                            TextField("Pen", text: $pen)
                        }
                        HStack {
                            Image(systemName: "drop")
                                .foregroundColor(.secondary)
                            TextField("Ink", text: $ink)
                        }
                        HStack {
                            Image(systemName: "doc.plaintext")
                                .foregroundColor(.secondary)
                            TextField("Paper", text: $paper)
                        }
                    }
                }
                Section(footer: Group {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Cancel")
                            .fullWidth(alignment: .center)
                    }
                    .padding()
                }) {
                    Button(action: {
                        Task {
                            let newEvent = await penpal.addEvent(ofType: eventType, notes: notes.isEmpty ? nil : notes, pen: pen.isEmpty ? nil : pen, ink: ink.isEmpty ? nil : ink, paper: paper.isEmpty ? nil : paper)
                            self.done(newEvent)
                        }
                    }) {
                        Text("Save")
                            .fullWidth(alignment: .center)
                    }
                    .tint(eventType.color)
                }
            }
        }
    }
}

struct AddEventSheet_Previews: PreviewProvider {
    static var previews: some View {
        AddEventSheet(penpal: PenPal(id: "1", name: "Alex Faber", initials: "AF", image: nil, _lastEventType: nil, lastEventDate: nil), eventType: .theyReceived) { newEvent in
        }
    }
}
