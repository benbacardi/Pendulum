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
    
    @State private var iconWidth: CGFloat = 20
    
    @FocusState private var isNotesFieldActive: Bool
    @FocusState private var isPenFieldActive: Bool
    @FocusState private var isInkFieldActive: Bool
    @FocusState private var isPaperFieldActive: Bool
    
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
    
    var autoSuggestions: [String] {
        let suggestions: [String]
        let st: String
        if isPenFieldActive {
            suggestions = penSuggestions
            st = pen
        }
        else if isInkFieldActive {
            suggestions = inkSuggestions
            st = ink
        }
        else if isPaperFieldActive {
            suggestions = paperSuggestions
            st = paper
        }
        else {
            suggestions = []
            st = ""
        }
        let search = st.lowercased().trimmingCharacters(in: .whitespaces)
        return suggestions.filter { $0.lowercased().contains(search) }
    }
    
    func chooseSuggestion(_ suggestion: String) {
        if isPenFieldActive { pen = suggestion }
        else if isInkFieldActive { ink = suggestion }
        else if isPaperFieldActive { paper = suggestion }
        clearFocus()
    }
    
    func clearFocus() {
        isNotesFieldActive = false
        isPenFieldActive = false
        isInkFieldActive = false
        isPaperFieldActive = false
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
                                    HStack {
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack {
                                                ForEach(autoSuggestions, id: \.self) { suggestion in
                                                    Button(action: {
                                                        chooseSuggestion(suggestion)
                                                    }) {
                                                        Text(suggestion)
                                                    }
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                    .padding(5)
                                                    .background {
                                                        Color(uiColor: UIColor.secondarySystemBackground)
                                                    }
                                                }
                                            }
                                        }
                                        Spacer()
                                        Button(action: clearFocus) { Text("Done") }
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
                            HStack(alignment: .top) {
                                Image(systemName: "pencil")
                                    .foregroundColor(.secondary)
                                    .offset(y: 4)
                                    .background {
                                        GeometryReader { geo in
                                            Color.clear.preference(key: Self.IconWidthPreferenceKey.self, value: geo.size.width)
                                        }
                                    }
                                    .frame(width: iconWidth)
                                TextField(priorWrittenEvent?.pen ?? "Pen", text: $pen, axis: .vertical)
                                    .focused($isPenFieldActive)
                                if !penSuggestions.isEmpty {
                                    Button(action: {
                                        presentSuggestionSheetFor = TextOptions(text: $pen, options: penSuggestions, title: "Choose Pens")
                                    }) {
                                        Image(systemName: "ellipsis")
                                    }
                                    .offset(y: 8)
                                }
                            }
                            HStack(alignment: .top) {
                                Image(systemName: "drop")
                                    .foregroundColor(.secondary)
                                    .offset(y: 1)
                                    .background {
                                        GeometryReader { geo in
                                            Color.clear.preference(key: Self.IconWidthPreferenceKey.self, value: geo.size.width)
                                        }
                                    }
                                    .frame(width: iconWidth)
                                TextField(priorWrittenEvent?.ink ?? "Ink", text: $ink, axis: .vertical)
                                    .focused($isInkFieldActive)
                                if !inkSuggestions.isEmpty {
                                    Button(action: {
                                        presentSuggestionSheetFor = TextOptions(text: $ink, options: inkSuggestions, title: "Choose Inks")
                                    }) {
                                        Image(systemName: "ellipsis")
                                    }
                                    .offset(y: 8)
                                }
                            }
                            HStack(alignment: .top) {
                                Image(systemName: "doc.plaintext")
                                    .foregroundColor(.secondary)
                                    .offset(y: 1)
                                    .background {
                                        GeometryReader { geo in
                                            Color.clear.preference(key: Self.IconWidthPreferenceKey.self, value: geo.size.width)
                                        }
                                    }
                                    .frame(width: iconWidth)
                                TextField(priorWrittenEvent?.paper ?? "Paper", text: $paper, axis: .vertical)
                                    .focused($isPaperFieldActive)
                                if !paperSuggestions.isEmpty {
                                    Button(action: {
                                        presentSuggestionSheetFor = TextOptions(text: $paper, options: paperSuggestions, title: "Choose Paper")
                                    }) {
                                        Image(systemName: "ellipsis")
                                    }
                                    .offset(y: 8)
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
            .onPreferenceChange(Self.IconWidthPreferenceKey.self) { value in
                self.iconWidth = value
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
                    self.pen = event.pens.joined(separator: "\n")
                    self.ink = event.inks.joined(separator: "\n")
                    self.paper = event.papers.joined(separator: "\n")
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

private extension AddEventSheet {
    struct IconWidthPreferenceKey: PreferenceKey {
        static let defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = max(value, nextValue())
        }
    }
}
