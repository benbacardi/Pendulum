//
//  AddEventSheet.swift
//  Pendulum
//
//  Created by Ben Cardy on 21/11/2022.
//

import SwiftUI
import PhotosUI

struct AddEventSheet: View {
        
    @Environment(\.managedObjectContext) var moc
    
    // MARK: Parameters
    @ObservedObject var penpal: PenPal
    let event: Event?
    let done: () -> ()
    
    init(penpal: PenPal, eventType: EventType, done: @escaping () -> ()) {
        self._penpal = ObservedObject(wrappedValue: penpal)
        self.event = nil
        self._eventType = State(wrappedValue: eventType)
        self.done = done
    }
    
    init(penpal: PenPal, event: Event, done: @escaping () -> ()) {
        self._penpal = ObservedObject(wrappedValue: penpal)
        self.event = event
        self._eventType = State(wrappedValue: event.type)
        self.done = done
    }
    
    // MARK: State
    @State private var eventType: EventType = .written
    @State private var date: Date = Date()
    @State private var notes: String = ""
    @State private var pen: String = ""
    @State private var ink: String = ""
    @State private var paper: String = ""
    @State private var trackingReference: String = ""
    @State private var letterType: LetterType = .letter
    @State private var ignore: Bool = false
    @State private var noFurtherActions: Bool = false
    @State private var setToDefaultIgnoreWhenChangingLetterType: Bool = false
    
    @State private var eventPhotos: [EventPhoto] = []
    @State private var photoLoadPending: Bool = false
    @State private var photosLoadingCount: Int = 0
    
    @State private var showPickerChoice: Bool = false
    @State private var showPhotoPicker: Bool = false
    @State private var pickerType: UIImagePickerController.SourceType = .photoLibrary
    
    @State private var iconWidth: CGFloat = 20
    
    @FocusState private var isNotesFieldActive: Bool
    @FocusState private var isPenFieldActive: Bool
    @FocusState private var isInkFieldActive: Bool
    @FocusState private var isPaperFieldActive: Bool
    @FocusState private var isTrackingFieldActive: Bool
    
    @State private var penSuggestions: [String] = []
    @State private var inkSuggestions: [String] = []
    @State private var paperSuggestions: [String] = []
    
    @State private var presentSuggestionSheetFor: TextOptions? = nil
    
    @State private var priorWrittenEvent: Event? = nil
    
    @State private var showEventTypeOptions: Bool = false
    @State private var thingsHaveChanged: Bool = false
    
    var priorWrittenEventHeaderText: String {
        guard let priorWrittenEvent = priorWrittenEvent else { return "" }
        return Calendar.current.verboseNumberOfDaysBetween(priorWrittenEvent.wrappedDate, and: Date())
    }
    
    var ignoreFooterText: String {
        if noFurtherActions {
            return "Pendulum will move \(penpal.wrappedName) to the \"No actions pending\" section if this is the most recent event."
        } else {
            if eventType == .written || eventType == .sent || eventType == .theyReceived {
                return "If enabled, Pendulum won't indicate that you are waiting for a response to this \(letterType.description)."
            } else {
                return "If enabled, Pendulum won't trigger prompts to respond to this \(letterType.description)."
            }
        }
    }
    
    func parseStationery(for stationery: String?) -> String? {
        stationery?.replacingOccurrences(of: ",", with: "\n")
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
        isTrackingFieldActive = false
    }
    
    @ViewBuilder
    var imagePickerView: some View {
        if pickerType == .camera {
            ImagePickerView(sourceType: pickerType) { image in
                let newEventPhoto = EventPhoto.from(image, in: moc)
                DispatchQueue.main.async {
                    withAnimation {
                        eventPhotos.append(newEventPhoto)
                        photoLoadPending = false
                    }
                }
            } onDismiss: {
                self.photoLoadPending = false
                self.showPhotoPicker = false
            }
        } else {
            PHImagePickerView { results in
                DispatchQueue.main.async {
                    photosLoadingCount = results.count
                }
                for result in results {
                    result.fetchImage { image in
                        let newEventPhoto = EventPhoto.from(image, in: moc)
                        DispatchQueue.main.async {
                            withAnimation {
                                photosLoadingCount -= 1
                                eventPhotos.append(newEventPhoto)
                                if photosLoadingCount <= 0 {
                                    photoLoadPending = false
                                }
                            }
                        }
                    }
                }
            } onDismiss: { photosCount in
                if photosCount == 0 {
                    self.photoLoadPending = false
                }
                self.showPhotoPicker = false
            }
        }
    }
    
    /// This path is not used, but an issue with iOS 17 prevents
    /// the keyboard toolbar from functioning correctly unless
    /// NavigationStack(path:) is used.
    /// See https://stackoverflow.com/questions/77238131/placing-the-toolbar-above-keyboard-does-not-work-in-ios-17
    @State private var path = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                Button(action: {
                    self.showEventTypeOptions = true
                }) {
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
                }
                .confirmationDialog("Change log type", isPresented: $showEventTypeOptions, titleVisibility: .visible) {
                    ForEach(EventType.actionableCases) { eventType in
                        Button(action: {
                            withAnimation {
                                self.eventType = eventType
                            }
                        }) {
                            Label(" \(eventType.actionableText)", systemImage: eventType.icon).tag(eventType)
                        }
                    }
                }
                Form {
                    if let event = event, eventType == .written && event.wrappedDate == penpal.lastEventDate && penpal.lastEventType == .written {
                        Section {
                            Button(action: {
                                withAnimation {
                                    penpal.sendLastWrittenEvent(in: moc, from: event)
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
                    }
                        
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
                                .foregroundColor(.accentColor)
                                .offset(y: 8)
                            }
                        }
                        .buttonStyle(.plain)
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
                    
                    Section {
                        Button(action: {
                            self.showPickerChoice = true
                        }) {
                            HStack {
                                Text("Add a photo…")
                                Spacer()
                                if photoLoadPending {
                                    ProgressView()
                                }
                            }
                        }
                        .confirmationDialog("Add a photo…", isPresented: $showPickerChoice) {
                            Button(action: {
                                self.pickerType = .photoLibrary
                                self.showPhotoPicker = true
                                self.photoLoadPending = true
                            }) {
                                Label("Photo Library", systemImage: "photo.on.rectangle")
                            }
                            Button(action: {
                                self.pickerType = .camera
                                self.showPhotoPicker = true
                                self.photoLoadPending = true
                            }) {
                                Label("Camera", systemImage: "camera")
                            }
                        }
                        .listRowSeparator(.hidden)
                        if !eventPhotos.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack {
                                    ForEach(eventPhotos) { photo in
                                        if let image = photo.thumbnail() ?? photo.image() {
                                            ZStack(alignment: .topTrailing) {
                                                image
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 100, height: 100)
                                                    .cornerRadius(10)
                                                Button(role: .destructive, action: {
                                                    let _ = withAnimation {
                                                        self.eventPhotos = self.eventPhotos.filter { $0.id != photo.id }
                                                    }
                                                }) {
                                                    ZStack(alignment: .topTrailing) {
                                                        Rectangle()
                                                            .fill(.clear)
                                                            .frame(width: 30, height: 30)
                                                        Label("Delete", systemImage: "minus.circle.fill")
                                                            .font(.headline)
                                                            .labelStyle(.iconOnly)
                                                            .foregroundColor(.gray)
                                                            .background(.white)
                                                            .clipShape(Circle())
                                                    }
                                                }
                                                .contentShape(Rectangle())
                                                .buttonStyle(.plain)
                                                .offset(x: 5, y: -5)
                                            }
                                        }
                                    }
                                }
                                .padding(.top, 5)
                                .padding([.horizontal, .bottom])
                            }
                            .listRowInsets(EdgeInsets())
                        }
                    }
                    .fullScreenCover(isPresented: $showPhotoPicker) {
                        imagePickerView
                            .edgesIgnoringSafeArea(.all)
                    }
                    
                    Section {
                        TextField("Tracking Reference", text: $trackingReference)
                            .focused($isTrackingFieldActive)
                    }
                    
                    Section(footer: Text(ignoreFooterText)) {
                        Toggle("No further actions", isOn: $noFurtherActions.animation())
                        if !noFurtherActions {
                            Toggle("No response needed", isOn: $ignore)
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
                                event.update(type: eventType, date: date, notes: notes.isEmpty ? nil : notes, pen: pen.isEmpty ? nil : parseStationery(for: pen), ink: ink.isEmpty ? nil : parseStationery(for: ink), paper: paper.isEmpty ? nil : parseStationery(for: paper), letterType: letterType, ignore: self.ignore, noFurtherActions: self.noFurtherActions, trackingReference: trackingReference.isEmpty ? nil : trackingReference, withPhotos: eventPhotos, in: moc)
                            } else {
                                penpal.addEvent(ofType: eventType, date: date, notes: notes.isEmpty ? nil : notes, pen: pen.isEmpty ? nil : parseStationery(for: pen), ink: ink.isEmpty ? nil : parseStationery(for: ink), paper: paper.isEmpty ? nil : parseStationery(for: paper), letterType: letterType, ignore: self.ignore, noFurtherActions: self.noFurtherActions, trackingReference: trackingReference.isEmpty ? nil : trackingReference, withPhotos: eventPhotos, in: moc)
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
                    .presentationDetents([.medium, .large])
            }
            .onChange(of: letterType) { newValue in
                if self.setToDefaultIgnoreWhenChangingLetterType {
                    self.ignore = newValue.defaultIgnore
                }
                self.thingsHaveChanged = true
            }
            .onChange(of: date) { _ in
                self.thingsHaveChanged = true
            }
            .onChange(of: notes) { _ in
                self.thingsHaveChanged = true
            }
            .onChange(of: pen) { _ in
                self.thingsHaveChanged = true
            }
            .onChange(of: ink) { _ in
                self.thingsHaveChanged = true
            }
            .onChange(of: paper) { _ in
                self.thingsHaveChanged = true
            }
            .onChange(of: trackingReference) { _ in
                self.thingsHaveChanged = true
            }
            .onChange(of: eventPhotos) { _ in
                self.thingsHaveChanged = true
            }
            .onPreferenceChange(Self.IconWidthPreferenceKey.self) { value in
                self.iconWidth = value
            }
            .onChange(of: eventType) { _ in
                updateStationery()
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
                    self.pen = parseStationery(for: event.pens.joined(separator: "\n")) ?? ""
                    self.ink = parseStationery(for: event.inks.joined(separator: "\n")) ?? ""
                    self.paper = parseStationery(for: event.papers.joined(separator: "\n")) ?? ""
                    self.trackingReference = event.trackingReference ?? ""
                    self.letterType = event.letterType
                    self.ignore = event.ignore
                    self.noFurtherActions = event.noFurtherActions
                    self.eventPhotos = event.allPhotos()
                    appLogger.debug("Event photos: \(self.eventPhotos)")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.thingsHaveChanged = false
                    }
                }
                updateStationery()
            }
            .task {
                if eventType == .sent && event == nil {
                    let priorSentEvent = penpal.fetchPriorEvent(to: Date(), ofType: .sent, ignore: false, from: moc)
                    let priorWrittenEvent = penpal.fetchPriorEvent(to: Date(), ofType: .written, ignore: false, from: moc)
                    if let priorWrittenEvent = priorWrittenEvent, priorSentEvent?.date ?? .distantPast < priorWrittenEvent.wrappedDate {
                        self.priorWrittenEvent = priorWrittenEvent
                        self.letterType = priorWrittenEvent.letterType
                        self.ignore = priorWrittenEvent.ignore
                    }
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
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
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                    Button(action: {
                        clearFocus()
                    }) { Text("Done")}
                }
            }
            .interactiveDismissDisabled(thingsHaveChanged)
        }
    }
    
    func updateStationery() {
        let outbound: Bool = eventType == .written || eventType == .sent
        self.penSuggestions = PenPal.fetchDistinctStationery(ofType: .pen, for: outbound ? nil : penpal, outbound: outbound, from: moc).map { $0.name }
        self.inkSuggestions = PenPal.fetchDistinctStationery(ofType: .ink, for: outbound ? nil : penpal, outbound: outbound, from: moc).map { $0.name }
        self.paperSuggestions = PenPal.fetchDistinctStationery(ofType: .paper, for: outbound ? nil : penpal, outbound: outbound, from: moc).map { $0.name }
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
