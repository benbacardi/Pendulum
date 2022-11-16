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
    let penpal: PenPal
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
    
    @State private var priorWrittenEvent: Event? = nil
    
    var priorWrittenEventHeaderText: String {
        guard let priorWrittenEvent = priorWrittenEvent else { return "" }
        return Calendar.current.verboseNumberOfDaysBetween(priorWrittenEvent.date, and: Date())
    }
    
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
                if let event = event {
                    
                    if event.eventType == .written && event.date == penpal.lastEventDate && penpal.lastEventType == .written {
                        Section {
                            Button(action: {
                                Task {
                                    let newEvent = await penpal.addEvent(ofType: .sent, notes: nil, pen: nil, ink: nil, paper: nil)
                                    let latestEventType = await penpal.updateLastEventType()
                                    self.done(newEvent, latestEventType)
                                }
                            }) {
                                HStack {
                                    Spacer()
                                    Image(systemName: EventType.sent.icon)
                                    Text("I've posted this!")
                                    Spacer()
                                }
                            }
                            .foregroundColor(EventType.sent.color)
                        }
                    }
                    
                }
                
                Section {
                    DatePicker("Date", selection: $date)
                }
                
                Section {
                    TextField("Notes", text: $notes, axis: .vertical)
                }
                if eventType == .written || eventType == .sent {
                    
                    Section(header: Group {
                        if priorWrittenEvent != nil {
                            Text("You wrote the letter \(priorWrittenEventHeaderText).").textCase(nil)
                        } else {
                            EmptyView()
                        }
                    }) {
                        HStack {
                            Image(systemName: "pencil")
                                .foregroundColor(.secondary)
                            HStack {
                                TextField(priorWrittenEvent?.pen ?? "Pen", text: $pen)
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
                                TextField(priorWrittenEvent?.ink ?? "Ink", text: $ink)
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
                                TextField(priorWrittenEvent?.paper ?? "Paper", text: $paper)
                                if !paperSuggestions.isEmpty {
                                    Button(action: {
                                        presentSuggestionSheetFor = TextOptions(text: $paper, options: paperSuggestions, title: "Choose a Paper")
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
                            if let event = event {
                                let newEvent = Event(id: event.id, _type: event._type, date: date, penpalID: event.penpalID, notes: notes.isEmpty ? nil : notes, pen: pen.isEmpty ? nil : pen, ink: ink.isEmpty ? nil : ink, paper: paper.isEmpty ? nil : paper, lastUpdated: Date(), dateDeleted: nil, cloudKitID: event.cloudKitID)
                                await event.update(from: newEvent)
                                let latestEventType = await penpal.updateLastEventType()
                                self.done(newEvent, latestEventType)
                            } else {
                                let newEvent = await penpal.addEvent(ofType: eventType, notes: notes.isEmpty ? nil : notes, pen: pen.isEmpty ? nil : pen, ink: ink.isEmpty ? nil : ink, paper: paper.isEmpty ? nil : paper, forDate: date)
                                let latestEventType = await penpal.updateLastEventType()
                                self.done(newEvent, latestEventType)
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
        }
        .task {
            self.penSuggestions = await AppDatabase.shared.fetchDistinctPens().map { $0.name }
            self.inkSuggestions = await AppDatabase.shared.fetchDistinctInks().map { $0.name }
            self.paperSuggestions = await AppDatabase.shared.fetchDistinctPapers().map { $0.name }
        }
        .task {
            if eventType == .sent && event == nil {
                let priorSentEvent = await penpal.fetchPriorEvent(to: Date(), ofType: .sent)
                let priorWrittenEvent = await penpal.fetchPriorEvent(to: Date(), ofType: .written)
                if let priorWrittenEvent = priorWrittenEvent, priorSentEvent?.date ?? .distantPast < priorWrittenEvent.date {
                    self.priorWrittenEvent = priorWrittenEvent
                }
            }
        }
    }
}

struct AddEventSheet_Previews: PreviewProvider {
    static let date: Date = Date()
    static var previews: some View {
        AddEventSheet(penpal: PenPal(id: UUID().uuidString, name: "Alex Faber", initials: "AF", image: nil, _lastEventType: EventType.written.rawValue, lastEventDate: AddEventSheet_Previews.date, notes: nil, lastUpdated: Date(), dateDeleted: nil, cloudKitID: nil), event: Event(id: UUID().uuidString, _type: EventType.written.rawValue, date: AddEventSheet_Previews.date, penpalID: UUID().uuidString, notes: "Notes", pen: nil, ink: nil, paper: "Paper", lastUpdated: Date(), dateDeleted: nil, cloudKitID: nil), eventType: .written) { newEvent, newEventType in
        }
    }
}
