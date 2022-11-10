//
//  AddEventSheet.swift
//  Pendulum
//
//  Created by Ben Cardy on 06/11/2022.
//

import SwiftUI
import PhotosUI

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

    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var selectedImageData: [Data] = []
    
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
                    
                    Section {
                        DatePicker("Date", selection: $date)
                    }
                    
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
                                    .buttonStyle(.plain)
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
                                    .buttonStyle(.plain)
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
                                        presentSuggestionSheetFor = TextOptions(text: $paper, options: paperSuggestions, title: "Choose a Paper}")
                                    }) {
                                        Image(systemName: "ellipsis")
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
                Section {
                    PhotosPicker(
                                selection: $selectedPhoto,
                                matching: .images,
                                photoLibrary: .shared()) {
                                    Text("Add a photo…")
                                }
                                .onChange(of: selectedPhoto) { newItem in
                                    Task {
                                        appLogger.debug("Selected photo: \(newItem.debugDescription)")
                                        do {
                                            if let data = try await newItem?.loadTransferable(type: Data.self) {
                                                DispatchQueue.main.async {
                                                    withAnimation {
                                                        selectedImageData.append(data)
                                                    }
                                                }
                                            }
                                        } catch {
                                            appLogger.debug("Could not load transferable: \(error.localizedDescription)")
                                        }
                                    }
                                }
                    if !selectedImageData.isEmpty {
                        ScrollView(.horizontal) {
                            LazyHStack {
                                ForEach(Array(zip(selectedImageData.indices, selectedImageData)), id: \.0) { index, imageData in
                                    if let image = UIImage(data: imageData) {
                                        ZStack(alignment: .topTrailing) {
                                            Image(uiImage: image)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 100, height: 100)
                                                .cornerRadius(10)
                                            Button(role: .destructive, action: {
                                                let _ = withAnimation {
                                                    selectedImageData.remove(at: index)
                                                }
                                            }) {
                                                Label("Delete", systemImage: "x.circle.fill")
                                                    .font(.headline)
                                                    .labelStyle(.iconOnly)
                                                    .foregroundColor(.red)
                                            }
                                            .buttonStyle(.plain)
                                            .backgroundCircle(color: .white, multiplier: 1.0)
                                            .offset(x: 5, y: -5)
                                        }
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
            if eventType == .sent && event == nil {
                Task {
                    let priorSentEvent = await penpal.fetchPriorEvent(to: Date(), ofType: .sent)
                    let priorWrittenEvent = await penpal.fetchPriorEvent(to: Date(), ofType: .written)
                    if let priorWrittenEvent = priorWrittenEvent, priorSentEvent?.date ?? .distantPast < priorWrittenEvent.date {
                        self.priorWrittenEvent = priorWrittenEvent
                    }
                }
            }
        }
    }
}

struct AddEventSheet_Previews: PreviewProvider {
    static let date: Date = Date()
    static var previews: some View {
        AddEventSheet(penpal: PenPal(id: "1", name: "Alex Faber", initials: "AF", image: nil, _lastEventType: EventType.written.rawValue, lastEventDate: AddEventSheet_Previews.date, notes: nil), event: Event(id: nil, _type: EventType.written.rawValue, date: AddEventSheet_Previews.date, penpalID: "1", notes: "Notes", pen: nil, ink: nil, paper: "Paper"), eventType: .written) { newEvent, newEventType in
        }
    }
}
