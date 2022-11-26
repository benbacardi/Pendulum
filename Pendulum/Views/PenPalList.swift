//
//  PenPalList.swift
//  Pendulum
//
//  Created by Ben Cardy on 18/11/2022.
//

import SwiftUI
import Contacts

struct PenPalGroup: Identifiable {
    let eventType: EventType
    let penpals: [PenPal]
    var id: Int { eventType.rawValue }
}

struct PenPalList: View {
    
    @Environment(\.managedObjectContext) var moc
    
    // MARK: State
    @AppStorage(UserDefaults.Key.stopAskingAboutContacts.rawValue, store: UserDefaults.shared) private var stopAskingAboutContacts: Bool = false
    
    @FetchRequest(sortDescriptors: [
        NSSortDescriptor(key: "lastEventDate", ascending: false),
    ], animation: .default) var penpals: FetchedResults<PenPal>
    @State private var contactsAccessStatus: CNAuthorizationStatus = .notDetermined
    @State private var iconWidth: CGFloat = .zero
    @State private var presentingSettingsSheet: Bool = false
    @State private var presentingAddPenPalSheet: Bool = false
    @State private var presentingManualAddPenPalSheet: Bool = false
    @State private var presentingStationerySheet: Bool = false
    @State private var currentPenPal: PenPal? = nil
    @State private var showDeleteAlert = false
    
    @ViewBuilder
    func sectionHeader(for type: EventType) -> some View {
        HStack {
            ZStack {
                Circle()
                    .fill(type.color)
                    .frame(width: iconWidth * 1.5, height: iconWidth * 1.5)
                Image(systemName: type.phraseIcon)
                    .font(Font.caption.weight(.bold))
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
            PenPalListItem(penpal: penpal)
        }
        .animation(.default, value: penpal)
        .swipeActions {
            Button(action: {
                withAnimation {
                    penpal.archive(!penpal.archived)
                }
            }) {
                Label(penpal.archived ? "Unarchive" : "Archive", systemImage: "archivebox")
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
            Button("Delete \(penpal.wrappedName)", role: .destructive) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    penpal.delete()
                    self.currentPenPal = nil
                }
            }
        }
    }
    
    @ViewBuilder
    var navigationBody: some View {
        if contactsAccessStatus != .authorized && penpals.isEmpty {
            /// Show contacts access required message if it hasn't been requested,
            /// or it has been denied and the user hasn't added any pen pals yet
            VStack {
                Spacer()
                if self.stopAskingAboutContacts {
                    if let image = UIImage(named: "undraw_directions_re_kjxs") {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: 200)
                            .padding(.bottom)
                    }
                    Text("Add a Pen Pal to get started!")
                } else {
                    ContactsAccessRequiredView(contactsAccessStatus: $contactsAccessStatus)
                }
                Spacer()
                Button(action: {
                    self.presentingManualAddPenPalSheet = true
                }) {
                    Text(self.stopAskingAboutContacts ? "Add Pen Pal" : "Add Pen Pal Manually")
                }
                Spacer()
            }
        } else if penpals.isEmpty {
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
            List(group(penpals)) { penpalGroup in
                sectionHeader(for: penpalGroup.eventType)
                    .listRowSeparator(.hidden)
                ForEach(penpalGroup.penpals, id: \.self) { penpal in
                    penPalNavigationLink(for: penpal)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                        .padding(.horizontal)
                        .padding(.vertical, 5)
                        .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
            .task {
                if !self.stopAskingAboutContacts {
                    await PenPal.syncWithContacts()
                }
            }
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
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            self.presentingStationerySheet = true
                        }) {
                            Label("Stationery", systemImage: "pencil.and.ruler")
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            if self.stopAskingAboutContacts {
                                self.presentingManualAddPenPalSheet = true
                            } else {
                                self.presentingAddPenPalSheet = true
                            }
                        }) {
                            Label("Add Pen Pal", systemImage: "plus.circle")
                        }
                    }
                }
        }
        .onPreferenceChange(PenPalListIconWidthPreferenceKey.self) { value in
            self.iconWidth = value
        }
        .sheet(isPresented: $presentingStationerySheet) {
            EventPropertyDetailsSheet(penpal: nil, allowAdding: true)
        }
        .sheet(isPresented: $presentingAddPenPalSheet) {
            AddPenPalSheet(existingPenPals: penpals)
        }
        .sheet(isPresented: $presentingManualAddPenPalSheet) {
            ManualAddPenPalSheet()
        }
        .sheet(isPresented: $presentingSettingsSheet) {
            SettingsList()
        }
        .onAppear {
            self.contactsAccessStatus = CNContactStore.authorizationStatus(for: .contacts)
        }
    }
    
    func group(_ result: FetchedResults<PenPal>) -> [PenPalGroup] {
        return Dictionary(grouping: result) {
            $0.archived ? .archived : $0.lastEventType
        }
        .map { PenPalGroup(eventType: $0.key, penpals: $0.value) }
        .sorted {
            $0.eventType.rawValue < $1.eventType.rawValue
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
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
