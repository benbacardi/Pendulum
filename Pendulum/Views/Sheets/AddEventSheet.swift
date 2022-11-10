//
//  AddEventSheet.swift
//  Pendulum
//
//  Created by Ben Cardy on 06/11/2022.
//

import SwiftUI

struct TextOptions: Identifiable {
    let id = UUID()
    let text: Binding<String>
    let options: [String]
    let title: String
}

struct AddEventSheet: View {
    
    // MARK: Environment
    @Environment(\.presentationMode) var presentationMode
    
    // MARK: Parameters
    let penpal: PenPal?
    let event: Event?
    let eventType: EventType
    let done: (Event?, EventType) -> ()
    
    // MARK: State
    @State private var date: Date = Date()
    @State private var notes: String = ""
    @State private var pen: String = ""
    @State private var ink: String = ""
    @State private var paper: String = ""
    
    @State private var penSuggestions: [String] = []
    @State private var inkSuggestions: [String] = []
    @State private var paperSuggestions: [String] = []
    
    @State private var presentSuggestionSheetFor: TextOptions? = nil
    
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
                if event != nil {
                    Section {
                        DatePicker("Date", selection: $date)
                    }
                }
                Section {
                    TextField("Notes", text: $notes, axis: .vertical)
                }
                if eventType == .written || eventType == .sent {
                    Section {
                        HStack {
                            Image(systemName: "pencil")
                                .foregroundColor(.secondary)
                            HStack {
                                TextField("Pen", text: $pen)
                                if !penSuggestions.isEmpty {
                                    Button(action: {
                                        presentSuggestionSheetFor = TextOptions(text: $pen, options: penSuggestions, title: "Choose a Pen")
                                    }) {
                                        Image(systemName: "ellipsis")
                                    }
                                }
                            }
                        }
                        HStack {
                            Image(systemName: "drop")
                                .foregroundColor(.secondary)
                            HStack {
                                TextField("Ink", text: $ink)
                                if !inkSuggestions.isEmpty {
                                    Button(action: {
                                        presentSuggestionSheetFor = TextOptions(text: $ink, options: inkSuggestions, title: "Choose an Ink")
                                    }) {
                                        Image(systemName: "ellipsis")
                                    }
                                }
                            }
                        }
                        HStack {
                            Image(systemName: "doc.plaintext")
                                .foregroundColor(.secondary)
                            HStack {
                                TextField("Paper", text: $paper)
                                if !paperSuggestions.isEmpty {
                                    Button(action: {
                                        presentSuggestionSheetFor = TextOptions(text: $paper, options: paperSuggestions, title: "Choose a Paper}")
                                    }) {
                                        Image(systemName: "ellipsis")
                                    }
                                }
                            }
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
                            if let penpal = penpal {
                                if let event = event {
                                    let newEvent = Event(id: event.id, _type: event._type, date: date, penpalID: event.penpalID, notes: notes.isEmpty ? nil : notes, pen: pen.isEmpty ? nil : pen, ink: ink.isEmpty ? nil : ink, paper: paper.isEmpty ? nil : paper)
                                    await event.update(from: newEvent)
                                    let latestEventType = await penpal.updateLastEventType()
                                    self.done(newEvent, latestEventType)
                                } else {
                                    let newEvent = await penpal.addEvent(ofType: eventType, notes: notes.isEmpty ? nil : notes, pen: pen.isEmpty ? nil : pen, ink: ink.isEmpty ? nil : ink, paper: paper.isEmpty ? nil : paper)
                                    let latestEventType = await penpal.updateLastEventType()
                                    self.done(newEvent, latestEventType)
                                }
                            }
                        }
                    }) {
                        Text(event == nil ? "Save" : "Update")
                            .fullWidth(alignment: .center)
                    }
                    .tint(eventType.color)
                }
            }
        }
        .sheet(item: $presentSuggestionSheetFor) { option in
            ChooseTextSheet(text: option.text, options: option.options, title: option.title)
        }
        .onAppear {
            if let event = event {
                date = event.date
                notes = event.notes ?? ""
                pen = event.pen ?? ""
                ink = event.ink ?? ""
                paper = event.paper ?? ""
            }
            Task {
                self.penSuggestions = await AppDatabase.shared.fetchDistinctPens()
                self.inkSuggestions = await AppDatabase.shared.fetchDistinctInks()
                self.paperSuggestions = await AppDatabase.shared.fetchDistinctPapers()
            }
        }
    }
}

struct AddEventSheet_Previews: PreviewProvider {
    static var previews: some View {
        AddEventSheet(penpal: PenPal(id: "1", name: "Alex Faber", initials: "AF", image: nil, _lastEventType: nil, lastEventDate: nil, notes: nil), event: Event(id: nil, _type: 2, date: Date(), penpalID: "1", notes: "Notes", pen: nil, ink: nil, paper: "Paper"), eventType: .written) { newEvent, newEventType in
        }
    }
}
