//
//  PenPalList.swift
//  Pendulum
//
//  Created by Ben Cardy on 04/11/2022.
//

import SwiftUI
import Contacts
import GRDB

struct PresentAddEventSheet: Identifiable {
    let id = UUID()
    let penpal: PenPal
    let eventType: EventType
}

struct PenPalList: View {
    
    // MARK: Environment
    @EnvironmentObject internal var orientationObserver: OrientationObserver
    
    // MARK: State
    @StateObject private var penPalListController = PenPalListController()
    @State private var contactsAccessStatus: CNAuthorizationStatus = .notDetermined
    @State private var presentingAddPenPalSheet: Bool = false
    @State private var iconWidth: CGFloat = .zero
    @State private var presentingSettingsSheet: Bool = false
    @State private var presentingStationerySheet: Bool = false
    @State private var presentAddEventSheetForType: PresentAddEventSheet? = nil
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var currentPenPal: PenPal? = nil
    @State private var showDeleteAlert = false
    
    func dateText(for penpal: PenPal) -> Text {
        if let date = penpal.lastEventDate {
            return Text("\(penpal.lastEventType.datePrefix) \(Calendar.current.verboseNumberOfDaysBetween(date, and: Date()))")
        } else {
            return Text("")
        }
    }
    
    @ViewBuilder
    func sectionHeader(for type: EventType) -> some View {
        HStack {
            ZStack {
                Circle()
                    .fill(type.color)
                    .frame(width: iconWidth * 1.5, height: iconWidth * 1.5)
                Image(systemName: type.phraseIcon)
                    .font(.caption)
                    .bold()
                    .foregroundColor(.white)
                    .background(GeometryReader { geo in
                        Color.clear.preference(key: PenPalListIconWidthPreferenceKey.self, value: max(geo.size.width, geo.size.height))
                    })
            }
            Text(type.phrase)
                .fullWidth()
                .font(.body)
                .foregroundColor(.primary)
        }
    }
    
    @ViewBuilder
    func penPalNavigationLink(for penpal: PenPal) -> some View {
        ZStack {
            NavigationLink(destination: PenPalView(penpal: penpal)) {
                EmptyView()
            }
            .opacity(0)
            .buttonStyle(.plain)
            GroupBox {
                HStack {
                    if let image = penpal.displayImage {
                        image
                            .clipShape(Circle())
                            .frame(width: 40, height: 40)
                    } else {
                        ZStack {
                            Circle()
                                .fill(.gray)
                            Text(penpal.initials)
                                .font(.system(.headline, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .frame(width: 40, height: 40)
                    }
                    VStack {
                        Text(penpal.name)
                            .font(.headline)
                            .fullWidth()
                        if penpal.lastEventDate != nil && penpal.lastEventType != .archived {
                            self.dateText(for: penpal)
                                .font(.caption)
                                .fullWidth()
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .foregroundColor(.primary)
            }
        }
        .swipeActions {
            Button(action: {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    Task {
                        if penpal.lastEventType != .archived {
                            await penpal.archive()
                        } else {
                            await penpal.updateLastEventType()
                        }
                    }
                }
            }) {
                if penpal.lastEventType != .archived {
                    Label("Archive", systemImage: "archivebox")
                } else {
                    Label("Unarchive", systemImage: "archivebox")
                }
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            Button(action: {
                self.currentPenPal = penpal
                self.showDeleteAlert = true
            }) {
                Label("Delete", systemImage: "trash")
            }
            .tint(.red)
        }
        .confirmationDialog("Are you sure?", isPresented: $showDeleteAlert, titleVisibility: .visible, presenting: currentPenPal) { penpal in
            Button("Delete \(penpal.name)", role: .destructive) {
                Task {
                    await penpal.delete()
                }
            }
        }
    }
    
    @ViewBuilder
    var navigationBody: some View {
        if contactsAccessStatus == .notDetermined || (contactsAccessStatus != .authorized && penPalListController.penpals.isEmpty) {
            /// Show contacts access required message if it hasn't been requested,
            /// or it has been denied and the user hasn't added any pen pals yet
            ContactsAccessRequiredView(contactsAccessStatus: $contactsAccessStatus)
        } else if penPalListController.penpals.isEmpty {
            VStack {
                Spacer()
                if !DeviceType.isPad() {
                    if let image = UIImage(named: "undraw_just_saying_re_kw9c") {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: 200)
                            .padding(.bottom)
                    }
                }
                Button(action: {
                    self.presentingAddPenPalSheet = true
                }) {
                    Text("Add your first Pen Pal to get started!")
                }
                Spacer()
            }
            .padding()
        } else {
            List {
                ForEach(EventType.allCases, id: \.self.rawValue) { eventType in
                    if let penpals = penPalListController.groupedPenPals[eventType] {
                        sectionHeader(for: eventType)
                        ForEach(penpals, id: \.id) { penpal in
                            penPalNavigationLink(for: penpal)
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets())
                                .padding(.horizontal)
                                .padding(.vertical, 5)
                        }
                    }
                }
                .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
        }
    }
    
    var body: some View {
        NavigationView {
            navigationBody
            .navigationTitle("Pen Pals")
            .toolbar {
                if DeviceType.isPad() {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            self.presentingSettingsSheet = true
                        }) {
                            Label("Settings", systemImage: "gear")
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        Task {
                            await CloudKitController.shared.performFullSync()
                        }
                    }) {
                        Label("Perform full sync!", systemImage: "tortoise")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        self.presentingStationerySheet = true
                    }) {
                        Label("Stationery", systemImage: "pencil.and.ruler")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        self.presentingAddPenPalSheet = true
                    }) {
                        Label("Add Pen Pal", systemImage: "plus.circle")
                    }
                    .disabled(contactsAccessStatus != .authorized)
                }
            }
            VStack {
                Spacer()
                if let image = UIImage(named: "undraw_directions_re_kjxs") {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 200)
                        .padding(.bottom)
                }
                Spacer()
            }
        }
        .sheet(isPresented: $presentingStationerySheet) {
            EventPropertyDetailsSheet(penpal: nil, allowAdding: true)
        }
        .sheet(isPresented: $presentingAddPenPalSheet) {
            AddPenPalSheet(existingPenPals: penPalListController.penpals)
        }
        .sheet(isPresented: $presentingSettingsSheet) {
            SettingsList()
        }
        .sheet(item: $presentAddEventSheetForType) { presentSheetData in
            AddEventSheet(penpal: presentSheetData.penpal, event: nil, eventType: presentSheetData.eventType) { newEvent, newEventType in
                self.presentAddEventSheetForType = nil
            }
        }
        .navigationSplitViewStyle(.balanced)
        .onPreferenceChange(PenPalListIconWidthPreferenceKey.self) { value in
            self.iconWidth = value
        }
        .onAppear {
            self.contactsAccessStatus = CNContactStore.authorizationStatus(for: .contacts)
            self.columnVisibility = .all
        }
        .onChange(of: orientationObserver.currentOrientation) { currentOrientation in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.columnVisibility = .all
            }
        }
        .task {
            await penPalListController.syncWithContacts()
        }
    }
}

struct PenPalListIconWidthPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct PenPalList_Previews: PreviewProvider {
    static var previews: some View {
        PenPalList()
    }
}
