//
//  AddEventSheet.swift
//  Pendulum
//
//  Created by Ben Cardy on 21/11/2022.
//

import SwiftUI

struct AddEventSheet: View {
        
    // MARK: Parameters
    @ObservedObject var penpal: PenPal
    let event: Event?
    let eventType: EventType
    let done: () -> ()
        
    // MARK: State
    @State private var date: Date = Date()
    @State private var notes: String = ""
    @State private var pen: String = ""
    @State private var ink: String = ""
    @State private var paper: String = ""
    @State private var letterType: LetterType = .letter
    @State private var ignore: Bool = false
    @State private var setToDefaultIgnoreWhenChangingLetterType: Bool = false
    @FocusState private var isNotesFieldActive: Bool
    
    @State private var penSuggestions: [String] = []
    @State private var inkSuggestions: [String] = []
    @State private var paperSuggestions: [String] = []
    
    @State private var presentSuggestionSheetFor: TextOptions? = nil
    
    @State private var priorWrittenEvent: Event? = nil
    
    var priorWrittenEventHeaderText: String {
        guard let priorWrittenEvent = priorWrittenEvent else { return "" }
        return Calendar.current.verboseNumberOfDaysBetween(priorWrittenEvent.wrappedDate, and: Date())
    }
    
    var ignoreFooterText: String {
        if eventType == .written || eventType == .sent || eventType == .theyReceived {
            return "If enabled, Pendulum won't indicate that you are waiting for a response to this \(letterType.description)."
        } else {
            return "If enabled, Pendulum won't trigger prompts to respond to this \(letterType.description)."
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                VStack(spacing: 4) {
                    Image(systemName: eventType.icon)
                        .font(.largeTitle)
                    Text("\(eventType.description(for: letterType))!")
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
                        Picker(selection: $letterType) {
                            ForEach(LetterType.allCases) { letterType in
                                /// This stupid space is necessary because iOS puts the icon
                                /// RIGHT UP IN THE POOR LABEL'S FACE in the picker view
                                Label(" \(letterType.properNoun)", systemImage: letterType.icon).tag(letterType)
                            }
                        } label: {
                            Text("Type")
                                .layoutPriority(0)
                        }
                    }
                    
                    Section {
                        TextField("Notes", text: $notes, axis: .vertical)
                            .focused($isNotesFieldActive)
                            .toolbar {
                                ToolbarItemGroup(placement: .keyboard) {
                                    Spacer()
                                    Button("Done") {
                                        isNotesFieldActive = false
                                    }
                                }
                            }
                    }
                    if eventType == .written || eventType == .sent {
                        
                        Section(header: Group {
                            if let priorWrittenEvent = priorWrittenEvent {
                                Text("You wrote the \(priorWrittenEvent.letterType.description) \(priorWrittenEventHeaderText).").textCase(nil)
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
                    
                    Section(footer: Text(ignoreFooterText)) {
                        Toggle("No response needed", isOn: $ignore)
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
                                event.update(date: date, notes: notes.isEmpty ? nil : notes, pen: pen.isEmpty ? nil : pen, ink: ink.isEmpty ? nil : ink, paper: paper.isEmpty ? nil : paper, letterType: letterType, ignore: self.ignore)
                            } else {
                                penpal.addEvent(ofType: eventType, date: date, notes: notes.isEmpty ? nil : notes, pen: pen.isEmpty ? nil : pen, ink: ink.isEmpty ? nil : ink, paper: paper.isEmpty ? nil : paper, letterType: letterType, ignore: self.ignore)
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
            .onChange(of: letterType) { newValue in
                if self.setToDefaultIgnoreWhenChangingLetterType {
                    self.ignore = newValue.defaultIgnore
                }
            }
            .onAppear {
                if event == nil {
                    self.setToDefaultIgnoreWhenChangingLetterType = true
                }
            }
            .task {
                if let event = event {
                    dataLogger.debug("Setting event details to: date=\(event.wrappedDate) notes=\(event.notes.debugDescription) pen=\(event.pen.debugDescription) ink=\(event.ink.debugDescription) paper=\(event.paper.debugDescription) ignore=\(event.ignore)")
                    self.date = event.wrappedDate
                    self.notes = event.notes ?? ""
                    self.pen = event.pen ?? ""
                    self.ink = event.ink ?? ""
                    self.paper = event.paper ?? ""
                    self.letterType = event.letterType
                    self.ignore = event.ignore
                }
            }
            .task {
                self.penSuggestions = PenPal.fetchDistinctStationery(ofType: .pen).map { $0.name }
                self.inkSuggestions = PenPal.fetchDistinctStationery(ofType: .ink).map { $0.name }
                self.paperSuggestions = PenPal.fetchDistinctStationery(ofType: .paper).map { $0.name }
            }
            .task {
                if eventType == .sent && event == nil {
                    let priorSentEvent = penpal.fetchPriorEvent(to: Date(), ofType: .sent, ignore: false)
                    let priorWrittenEvent = penpal.fetchPriorEvent(to: Date(), ofType: .written, ignore: false)
                    if let priorWrittenEvent = priorWrittenEvent, priorSentEvent?.date ?? .distantPast < priorWrittenEvent.wrappedDate {
                        self.priorWrittenEvent = priorWrittenEvent
                        self.letterType = priorWrittenEvent.letterType
                        self.ignore = priorWrittenEvent.ignore
                    }
                }
            }
        }
    }
}
