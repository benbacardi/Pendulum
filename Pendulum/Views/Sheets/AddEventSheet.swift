//
//  AddEventSheet.swift
//  Pendulum
//
//  Created by Ben Cardy on 21/11/2022.
//

import SwiftUI

struct AddEventSheet: View {
        
    // MARK: Parameters
    let penpal: PenPal
    let event: Event?
    let eventType: EventType
    let done: () -> ()
    
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
        return Calendar.current.verboseNumberOfDaysBetween(priorWrittenEvent.wrappedDate, and: Date())
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
                    
                    if event.type == .written && event.wrappedDate == penpal.lastEventDate && penpal.lastEventType == .written {
                        Section {
                            Button(action: {
                                withAnimation {
                                    penpal.addEvent(ofType: .sent)
                                    done()
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
                        done()
                    }) {
                        Text("Cancel")
                            .fullWidth(alignment: .center)
                    }
                    .padding()
                }) {
                    Button(action: {
                        if let event = event {
                            event.update(date: date, notes: notes.isEmpty ? nil : notes, pen: pen.isEmpty ? nil : pen, ink: ink.isEmpty ? nil : ink, paper: paper.isEmpty ? nil : paper)
                        } else {
                            penpal.addEvent(ofType: eventType, date: date, notes: notes.isEmpty ? nil : notes, pen: pen.isEmpty ? nil : pen, ink: ink.isEmpty ? nil : ink, paper: paper.isEmpty ? nil : paper)
                        }
                        done()
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
                self.date = event.wrappedDate
                self.notes = event.notes ?? ""
                self.pen = event.pen ?? ""
                self.ink = event.ink ?? ""
                self.paper = event.paper ?? ""
            }
        }
        .task {
            self.penSuggestions = PenPal.fetchDistinctStationery(ofType: .pen).map { $0.name }
            self.inkSuggestions = PenPal.fetchDistinctStationery(ofType: .ink).map { $0.name }
            self.paperSuggestions = PenPal.fetchDistinctStationery(ofType: .paper).map { $0.name }
        }
        .task {
            if eventType == .sent && event == nil {
                let priorSentEvent = penpal.fetchPriorEvent(to: Date(), ofType: .sent)
                let priorWrittenEvent = penpal.fetchPriorEvent(to: Date(), ofType: .written)
                if let priorWrittenEvent = priorWrittenEvent, priorSentEvent?.date ?? .distantPast < priorWrittenEvent.wrappedDate {
                    self.priorWrittenEvent = priorWrittenEvent
                }
            }
        }
    }
}
