//
//  CDPenPalList.swift
//  Pendulum
//
//  Created by Ben Cardy on 18/11/2022.
//

import SwiftUI
import Contacts

struct PenPalGroup: Identifiable {
    let eventType: EventType
    let penpals: [CDPenPal]
    var id: Int { eventType.rawValue }
}

struct CDPenPalList: View {
    
    @Environment(\.managedObjectContext) var moc
    
    // MARK: State
    @FetchRequest(sortDescriptors: []) var penpals: FetchedResults<CDPenPal>
    @State private var contactsAccessStatus: CNAuthorizationStatus = .notDetermined
    @State private var iconWidth: CGFloat = .zero
    @State private var presentingSettingsSheet: Bool = false
    @State private var presentingAddPenPalSheet: Bool = false
    @State private var presentingStationerySheet: Bool = false
    
    func dateText(for penpal: CDPenPal) -> Text {
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
    func penPalNavigationLink(for penpal: CDPenPal) -> some View {
        ZStack {
//            NavigationLink(destination: PenPalView(penpal: penpal)) {
//                EmptyView()
//            }
//            .opacity(0)
//            .buttonStyle(.plain)
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
                            Text(penpal.wrappedInitials)
                                .font(.system(.headline, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .frame(width: 40, height: 40)
                    }
                    VStack {
                        Text(penpal.wrappedName)
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
//        .swipeActions {
//            Button(action: {
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
//                    Task {
//                        if penpal.lastEventType != .archived {
//                            await penpal.archive()
//                        } else {
//                            await penpal.updateLastEventType()
//                        }
//                    }
//                }
//            }) {
//                if penpal.lastEventType != .archived {
//                    Label("Archive", systemImage: "archivebox")
//                } else {
//                    Label("Unarchive", systemImage: "archivebox")
//                }
//            }
//        }
//        .swipeActions(edge: .leading, allowsFullSwipe: false) {
//            Button(action: {
//                self.currentPenPal = penpal
//                self.showDeleteAlert = true
//            }) {
//                Label("Delete", systemImage: "trash")
//            }
//            .tint(.red)
//        }
//        .confirmationDialog("Are you sure?", isPresented: $showDeleteAlert, titleVisibility: .visible, presenting: currentPenPal) { penpal in
//            Button("Delete \(penpal.name)", role: .destructive) {
//                Task {
//                    await penpal.delete()
//                }
//            }
//        }
    }
    
    @ViewBuilder
    var navigationBody: some View {
        if contactsAccessStatus == .notDetermined || (contactsAccessStatus != .authorized && penpals.isEmpty) {
            /// Show contacts access required message if it hasn't been requested,
            /// or it has been denied and the user hasn't added any pen pals yet
            ContactsAccessRequiredView(contactsAccessStatus: $contactsAccessStatus)
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
                            self.presentingAddPenPalSheet = true
                        }) {
                            Label("Add Pen Pal", systemImage: "plus.circle")
                        }
                        .disabled(contactsAccessStatus != .authorized)
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
//            AddPenPalSheet(existingPenPals: penPalListController.penpals)
        }
        .sheet(isPresented: $presentingSettingsSheet) {
            SettingsList()
        }
        .onAppear {
            self.contactsAccessStatus = CNContactStore.authorizationStatus(for: .contacts)
        }
    }
    
    func group(_ result: FetchedResults<CDPenPal>) -> [PenPalGroup] {
        return Dictionary(grouping: result) { $0.lastEventTypeValue }
            .map { PenPalGroup(eventType: EventType.from($0.key), penpals: $0.value) }
    }
    
}

struct CDPenPalList_Previews: PreviewProvider {
    static var previews: some View {
        CDPenPalList()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
