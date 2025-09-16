//
//  PenPalView.swift
//  Pendulum
//
//  Created by Ben Cardy on 21/11/2022.
//

import SwiftUI
import Contacts

struct PenPalView: View {
    
    // MARK: Environment
    @Environment(\.managedObjectContext) var moc
    @Environment(\.colorScheme) var colorScheme
    
    // MARK: Parameters
    @ObservedObject var penpal: PenPal
    let didSave =  NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)
    
    // MARK: State
    @FetchRequest var events: FetchedResults<Event>
    @State private var buttonHeight: CGFloat?
    @State private var presentAddEventSheetForType: EventType? = nil
    @State private var refreshID = UUID()
    @State private var showingPenPalContactSheet: Bool = false
    @State private var presentPropertyDetailsSheet: Bool = false
    
    @State private var eventsWithDifferences: [(Event, Int)] = []
    
    init(penpal: PenPal) {
        self.penpal = penpal
        self._events = FetchRequest<Event>(
            sortDescriptors: [
                NSSortDescriptor(key: "date", ascending: false)
            ],
            predicate: NSPredicate(format: "penpal = %@", penpal),
            animation: .default
        )
    }
    
    @ViewBuilder
    var eventTypeMenu: some View {
        ForEach(EventType.actionableCases, id: \.self) { eventType in
            Button(action: {
                self.userTappedAddEvent(ofType: eventType)
            }) {
                Label(eventType.actionableText, systemImage: eventType.icon)
            }
        }
    }
    
    @ViewBuilder
    func headerAndButtons() -> some View {
        Group {
            
            PenPalHeader(penpal: penpal)
                .padding(.horizontal)
            
            if penpal.lastEventType != .noEvent && !penpal.archived && penpal.lastEventType != .nothingToDo {
                Text(penpal.lastEventType.phrase)
                    .fullWidth()
                    .padding(.horizontal)
            }
            
            Grid {
                GridRow {
                    
                    if penpal.archived {
                        Button(action: {
                            withAnimation {
                                penpal.archive(false, in: moc)
                            }
                        }) {
                            Label("Unarchive", systemImage: EventType.archived.icon)
                                .fullWidth(alignment: .center)
                                .font(.headline)
                                .background(GeometryReader { geometry in
                                    Color.clear.preference(key: ButtonHeightPreferenceKey.self, value: geometry.size.height)
                                })
                        }
                        .tint(EventType.archived.color)
                        .buttonStyle(.borderedProminent)
                    } else {
                        ForEach(penpal.lastEventType.nextLogicalEventTypes, id: \.self) { eventType in
                            if #available(iOS 26, *) {
                                Button(action: {
                                    self.userTappedAddEvent(ofType: eventType)
                                }) {
                                    Label(eventType.actionableTextShort, systemImage: eventType.icon)
                                        .fullWidth(alignment: .center)
                                        .foregroundStyle(.white)
                                }
                                .buttonStyle(.glass(.regular.tint(eventType.color)))
                                .background(GeometryReader { geometry in
                                    Color.clear.preference(key: ButtonHeightPreferenceKey.self, value: geometry.size.height)
                                })
                            } else {
                                Button(action: {
                                    self.userTappedAddEvent(ofType: eventType)
                                }) {
                                    Label(eventType.actionableTextShort, systemImage: eventType.icon)
                                        .fullWidth(alignment: .center)
                                        .font(.headline)
                                        .background(GeometryReader { geometry in
                                            Color.clear.preference(key: ButtonHeightPreferenceKey.self, value: geometry.size.height)
                                        })
                                }
                                .tint(eventType.color)
                                .buttonStyle(.borderedProminent)
                            }
                        }
                    }
                    if #available(iOS 26, *) {
                        Menu {
                            eventTypeMenu
                        } label: {
                            ZStack {
                                Text(" ")
                                Label("More actions", systemImage: "ellipsis")
                                    .labelStyle(.iconOnly)
                            }
                        }
                        .buttonStyle(.glass)
                    } else {
                        Menu {
                            eventTypeMenu
                        } label: {
                            ZStack {
                                Text(" ")
                                Label("More actions", systemImage: "ellipsis")
                                    .labelStyle(.iconOnly)
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    
                }
            }
            .padding(.horizontal)
        }
    }
    
    @ViewBuilder
    func dateDivider(for date: Date, withDifference difference: Int, relativeToToday: Bool = false) -> some View {
        let plural = difference > 1 ? "s" : ""
        HStack {
            if relativeToToday {
                if difference == 0 {
                    Text("Today")
                } else {
                    Text("\(difference) day\(plural) ago")
                }
            } else {
                Text("\(difference) day\(plural) before")
            }
            Text("–")
            Text(date, style: .date)
        }
        .font(.caption)
        .foregroundColor(.secondary)
    }
    
    var body: some View {
        VStack(spacing: 10) {
            self.headerAndButtons()
            if events.isEmpty {
                Spacer()
                if let image = UIImage(named: "undraw_letter_re_8m03") {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 200)
                }
                Text("It seems you haven't sent or received any letters with \(penpal.wrappedName) yet!")
                    .fullWidth(alignment: .center)
                    .padding()
                    .padding(.top)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        
                        if let firstEvent = self.eventsWithDifferences.first, firstEvent.0.type != .noEvent {
                            let difference = Calendar.current.numberOfDaysBetween(firstEvent.0.wrappedDate, and: Date())
                            self.dateDivider(for: firstEvent.0.wrappedDate, withDifference: difference, relativeToToday: true)
                                .padding(.bottom)
                        }
                        
                        ForEach(self.eventsWithDifferences, id: \.0.id) { (event, difference) in
                            if event.type != .noEvent {
                                if difference > 0 {
                                    dateDivider(for: event.wrappedDate, withDifference: difference)
                                        .padding(.bottom)
                                }
                                EventCell(event: event, penpal: penpal)
                                    .groupBoxStyle(ExtendedGroupBoxStyle(background: colorScheme == .dark ? Color(.secondarySystemGroupedBackground) : Color(.systemGroupedBackground), includePadding: false))
                                    .padding(.bottom)
                            }
                        }
                    }
                    .padding()
                }
                .id(refreshID)
            }
        }
        .sheet(isPresented: $showingPenPalContactSheet) {
            PenPalContactSheet(penpal: penpal)
        }
        .sheet(isPresented: $presentPropertyDetailsSheet) {
            EventPropertyDetailsSheet(penpal: penpal)
        }
        .sheet(item: $presentAddEventSheetForType) { eventType in
            AddEventSheet(penpal: penpal, eventType: eventType) {
                Task {
                    await self.updateEventsList()
                }
                self.presentAddEventSheetForType = nil
            }
        }
        .toolbar {
            Button(action: {
                self.presentPropertyDetailsSheet = true
            }) {
                Label("Stationery", systemImage: "pencil.and.ruler")
            }
            Button(action: {
                self.showingPenPalContactSheet = true
            }){
                Label("Pen Pal Addresses", systemImage:"person.crop.circle")
            }
        }
        .onReceive(self.didSave) { _ in
            Task {
                await updateEventsList()
            }
        }
        .onPreferenceChange(ButtonHeightPreferenceKey.self) {
            self.buttonHeight = $0
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            penpal.syncWithContact()
        }
        .task {
            await updateEventsList()
        }
    }
    
    func updateEventsList() async {
        withAnimation {
            self.eventsWithDifferences = self.eventsWithDifferences(for: self.events)
            self.refreshID = UUID()
        }
    }
    
    func userTappedAddEvent(ofType eventType: EventType) {
        if eventType.presentFullNotesSheetByDefault && !UserDefaults.shared.enableQuickEntry {
            self.presentAddEventSheetForType = eventType
        } else {
            withAnimation {
                penpal.addEvent(ofType: eventType, in: moc)
            }
        }
    }
    
    private func eventsWithDifferences(for events: FetchedResults<Event>) -> [(Event, Int)] {
        var intermediate: [(Event, Int)] = []
        let calendar = Calendar.current
        for (index, item) in events.enumerated() {
            if index == 0 {
                intermediate.append((item, 0))
                continue
            }
            let newIndex = index - 1
            let newItem = events[newIndex]
            intermediate.append((item, calendar.numberOfDaysBetween(item.wrappedDate, and: newItem.wrappedDate)))
        }
        return intermediate
    }
    
}

private extension PenPalView {
    struct ButtonHeightPreferenceKey: PreferenceKey {
        static let defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = max(value, nextValue())
        }
    }
}
