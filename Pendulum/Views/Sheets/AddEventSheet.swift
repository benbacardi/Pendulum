//
//  AddEventSheet.swift
//  Pendulum
//
//  Created by Ben Cardy on 21/11/2022.
//

import SwiftUI
import PhotosUI

struct CustomStationeryTypeView: View {
    @Environment(\.managedObjectContext) var moc

    @Binding var type: CustomStationeryType
    @Binding var iconWidth: CGFloat

    @State private var suggestions: [String] = []

    var body: some View {
        StationeryTypeView(icon: type.icon, title: type.type, text: $type.value, suggestions: suggestions, suggestionTitle: "Choose \(type.type)", iconWidth: $iconWidth)
            .task {
                let type = type.type
                suggestions = await PersistenceController.shared.fetching { context in
                    CustomStationery.fetchDistinctValues(ofType: type, from: context)
                }
            }
    }
}

struct StationeryTypeView: View {

    let icon: String
    let title: String
    @Binding var text: String
    let suggestions: [String]
    let suggestionTitle: String
    @Binding var iconWidth: CGFloat

    @FocusState private var isTextFieldActive: Bool
    @State private var presentSuggestionSheetFor: TextOptions? = nil

    var autoSuggestions: [String] {
        let search = text.lowercased().trimmingCharacters(in: .whitespaces)
        return suggestions.filter { $0.lowercased().contains(search) }
    }

    var image: Image {
        StationeryType.image(forIcon: icon)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                image
                    .foregroundStyle(.secondary)
                    .background {
                        GeometryReader { geo in
                            Color.clear.preference(key: AddEventSheet.IconWidthPreferenceKey.self, value: geo.size.width)
                        }
                    }
                    .frame(width: iconWidth)
                Text("?")
                    .accessibilityHidden(true)
                    .opacity(0)
            }
            TextField(title, text: $text, axis: .vertical)
                .focused($isTextFieldActive)
            if !suggestions.isEmpty {
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text("?")
                        .accessibilityHidden(true)
                        .opacity(0)
                    Button(suggestionTitle, systemImage: "ellipsis") {
                        presentSuggestionSheetFor = TextOptions(text: $text, options: suggestions, title: suggestionTitle)
                    }
                    .labelStyle(.iconOnly)
                }
            }
        }
        .toolbar {
            if isTextFieldActive {
                ToolbarItemGroup(placement: .keyboard) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(autoSuggestions, id: \.self) { suggestion in
                                Button(action: {
                                    text = suggestion
                                }) {
                                    Text(suggestion)
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(5)
                                .background {
                                    Color(uiColor: UIColor.secondarySystemBackground)
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                    Button(action: {
                        isTextFieldActive = false
                    }) { Text("Done")}
                }
            }
        }
        .sheet(item: $presentSuggestionSheetFor) { option in
            ChooseTextSheet(text: option.text, options: option.options, title: option.title)
                .presentationDetents([.medium, .large])
        }
    }

}

struct AddStationeryTypeForm: View {
    @State private var typeName: String = ""
    @State private var icon: String = "envelope"
    @State private var showPicker: Bool = false
    @Environment(\.managedObjectContext) private var moc
    @State private var existingTypeNames: [String] = []
    let initial: CustomStationeryType?
    let done: (CustomStationeryType) -> ()

    var isDuplicate: Bool {
        let trimmed = typeName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return existingTypeNames.contains { $0.lowercased() == trimmed }
    }

    @ViewBuilder
    var iconHeader: some View {
        HStack {
            Spacer()
            Button(action: { showPicker = true }) {
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 80, height: 80)
                        Image(systemName: icon)
                            .font(.system(size: 32))
                            .foregroundStyle(.white)
                    }
                    Text("Change Icon")
                        .font(.caption)
                }
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .padding(.bottom)
        .textCase(nil)
    }

    var body: some View {
        Form {
            Section(header: iconHeader) {
                TextField("Name", text: $typeName)
                if isDuplicate {
                    Text("A category with this name already exists.")
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }
            Section {
                Button(action: {
                    let type = CustomStationeryType(type: typeName, icon: icon, value: "")
                    done(type)
                }) {
                    Text(initial == nil ? "Add" : "Update")
                        .fullWidth(alignment: .center)
                }
                .disabled(typeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isDuplicate)
            }
        }
        .sheet(isPresented: $showPicker) {
            SymbolPicker(selectedSymbol: $icon) {
                showPicker = false
            }
        }
        .task {
            if let initial {
                self.typeName = initial.type
                self.icon = initial.icon
            }
            // Fetch all existing types except the current one (if editing)
            let allTypes = CustomStationery.fetchDistinctTypes(from: moc).map { $0.type }
            if let initial {
                self.existingTypeNames = allTypes.filter { $0.caseInsensitiveCompare(initial.type) != .orderedSame }
            } else {
                self.existingTypeNames = allTypes
            }
        }
    }
}

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
    @FocusState private var isTrackingFieldActive: Bool

    @State private var penSuggestions: [String] = []
    @State private var inkSuggestions: [String] = []
    @State private var paperSuggestions: [String] = []

    @State private var priorWrittenEvent: Event? = nil

    @State private var showEventTypeOptions: Bool = false
    @State private var thingsHaveChanged: Bool = false

    @State private var customStationeryTypes: [CustomStationeryType] = []

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

    func clearFocus() {
        isNotesFieldActive = false
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

    @ViewBuilder
    var largeHeaderText: some View {
        VStack(spacing: 4) {
            Image(systemName: eventType.icon)
                .font(.largeTitle)
            Text("\(eventType.description(for: letterType))!")
                .font(.largeTitle)
                .bold()
                .fullWidth(alignment: .center)
        }
    }

    @ViewBuilder
    var formHeaderPadding: some View {
        largeHeaderText
            .padding(.bottom, 48)
            .opacity(0)
    }

    @ViewBuilder
    var formHeaderPaddingOrNone: some View {
        Group {
            if !hasSendButton {
                formHeaderPadding
            }
        }
    }

    var hasSendButton: Bool {
        if let event = event, eventType == .written && event.wrappedDate == penpal.lastEventDate && penpal.lastEventType == .written {
            return true
        }
        return false
    }

    @ViewBuilder
    var largeHeaderButton: some View {
        Button(action: {
            self.showEventTypeOptions = true
        }) {
            largeHeaderText
                .foregroundStyle(.white)
                .padding()
                .padding(.top, 48)
                .padding(.vertical)
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
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack(alignment: .top) {
                Form {

                    if hasSendButton {
                        Section(header: formHeaderPadding) {
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
                            .foregroundStyle(EventType.sent.color)
                        }
                    }

                    Section(header: formHeaderPaddingOrNone) {
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
                        StationeryTypeView(icon: StationeryType.pen.icon, title: priorWrittenEvent?.pen ?? "Pen", text: $pen, suggestions: penSuggestions, suggestionTitle: "Choose Pens", iconWidth: $iconWidth)
                        StationeryTypeView(icon: StationeryType.ink.icon, title: priorWrittenEvent?.ink ?? "Ink", text: $ink, suggestions: inkSuggestions, suggestionTitle: "Choose Inks", iconWidth: $iconWidth)
                        StationeryTypeView(icon: StationeryType.paper.icon, title: priorWrittenEvent?.paper ?? "Paper", text: $paper, suggestions: paperSuggestions, suggestionTitle: "Choose Paper", iconWidth: $iconWidth)

                        ForEach($customStationeryTypes) { $customStationeryType in
                            CustomStationeryTypeView(type: $customStationeryType, iconWidth: $iconWidth)
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
                                                    .clipShape(.rect(cornerRadius: 10))
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
                                                            .foregroundStyle(.gray)
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
                }

                if #available(iOS 26, *) {
                    largeHeaderButton
                        .glassEffect(.clear.tint(eventType.color).interactive(), in: .rect)
                        .edgesIgnoringSafeArea(.top)
                } else {
                    largeHeaderButton
                        .background(eventType.color)
                        .edgesIgnoringSafeArea(.top)
                }

            }
            .fullScreenCover(isPresented: $showPhotoPicker) {
                imagePickerView
                    .edgesIgnoringSafeArea(.all)
            }
            .onChange(of: letterType) { _, newValue in
                if self.setToDefaultIgnoreWhenChangingLetterType {
                    self.ignore = newValue.defaultIgnore
                }
                self.thingsHaveChanged = true
            }
            .onChange(of: date) {
                self.thingsHaveChanged = true
            }
            .onChange(of: notes) {
                self.thingsHaveChanged = true
            }
            .onChange(of: pen) {
                self.thingsHaveChanged = true
            }
            .onChange(of: ink) {
                self.thingsHaveChanged = true
            }
            .onChange(of: paper) {
                self.thingsHaveChanged = true
            }
            .onChange(of: trackingReference) {
                self.thingsHaveChanged = true
            }
            .onChange(of: eventPhotos) {
                self.thingsHaveChanged = true
            }
            .onPreferenceChange(Self.IconWidthPreferenceKey.self) { value in
                self.iconWidth = value
            }
            .task(id: eventType) {
                await updateStationery()
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
                    self.customStationeryTypes = event.allCustomStationeryTypes(from: moc)
                    appLogger.debug("Event photos: \(self.eventPhotos)")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.thingsHaveChanged = false
                    }
                } else {
                    self.customStationeryTypes = CustomStationery.fetchDistinctTypes(from: moc)
                }
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
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        done()
                    }) {
                        Label("Cancel", systemImage: "xmark")
                            .labelStyleIconOnlyOn26()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        if let event = event {
                            event.update(type: eventType, date: date, notes: notes.isEmpty ? nil : notes, pen: pen.isEmpty ? nil : parseStationery(for: pen), ink: ink.isEmpty ? nil : parseStationery(for: ink), paper: paper.isEmpty ? nil : parseStationery(for: paper), letterType: letterType, ignore: self.ignore, noFurtherActions: self.noFurtherActions, trackingReference: trackingReference.isEmpty ? nil : trackingReference, withPhotos: eventPhotos, withCustomStationeryTypes: customStationeryTypes, in: moc)
                        } else {
                            penpal.addEvent(ofType: eventType, date: date, notes: notes.isEmpty ? nil : notes, pen: pen.isEmpty ? nil : parseStationery(for: pen), ink: ink.isEmpty ? nil : parseStationery(for: ink), paper: paper.isEmpty ? nil : parseStationery(for: paper), letterType: letterType, ignore: self.ignore, noFurtherActions: self.noFurtherActions, trackingReference: trackingReference.isEmpty ? nil : trackingReference, withPhotos: eventPhotos, withCustomStationeryTypes: customStationeryTypes, in: moc)
                        }
                        done()
                    }) {
                        Label(event == nil ? "Save" : "Update", systemImage: "checkmark")
                            .labelStyleIconOnlyOn26()
                    }
                }

            }
            .interactiveDismissDisabled(thingsHaveChanged)
        }
    }

    func updateStationery() async {
        let outbound: Bool = eventType == .written || eventType == .sent
        let penpalID = outbound ? nil : penpal.objectID
        let suggestions = await PersistenceController.shared.fetching { context in
            let penpal: PenPal? = penpalID.flatMap { id in
                (try? context.existingObject(with: id)) as? PenPal
            }
            return (
                pens: PenPal.fetchDistinctStationery(ofType: .pen, for: penpal, outbound: outbound, from: context).map { $0.name },
                inks: PenPal.fetchDistinctStationery(ofType: .ink, for: penpal, outbound: outbound, from: context).map { $0.name },
                papers: PenPal.fetchDistinctStationery(ofType: .paper, for: penpal, outbound: outbound, from: context).map { $0.name }
            )
        }
        self.penSuggestions = suggestions.pens
        self.inkSuggestions = suggestions.inks
        self.paperSuggestions = suggestions.papers
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
