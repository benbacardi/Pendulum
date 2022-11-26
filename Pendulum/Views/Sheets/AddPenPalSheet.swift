//
//  AddPenPalSheet.swift
//  Pendulum
//
//  Created by Ben Cardy on 04/11/2022.
//

import SwiftUI
import Contacts

struct AddPenPalSheet: View {
    
    // MARK: Environment
    @Environment(\.managedObjectContext) var moc
    @Environment(\.presentationMode) var presentationMode
    
    // MARK: Parameters
    let existingPenPals: FetchedResults<PenPal>
    
    // MARK: State
    @State private var contactsAccessStatus: CNAuthorizationStatus = .notDetermined
    @State private var existingPenPalIdentifiers: Set<String> = []
    @State private var contactDetails: [CNContact] = []
    @State private var contactsFetched: Bool = false
    @State private var filteredContacts: [CNContact] = []
    @State private var searchText: String = ""
    @State private var presentingManualAddPenPalSheet: Bool = false
    
    var body: some View {
        NavigationStack {
            Group {
                if !contactDetails.isEmpty {
                    List {
                        Button(action: {
                            self.presentingManualAddPenPalSheet = true
                        }) {
                            Text("Add Pen Pal Manually…")
                        }
                        ForEach(filteredContacts, id: \.identifier) { contact in
                            if !existingPenPalIdentifiers.contains(contact.identifier) {
                                Button(action: {
                                    Task {
                                        let newPenPal = PenPal(context: moc)
                                        newPenPal.id = UUID()
                                        newPenPal.name = contact.fullName
                                        newPenPal.initials = contact.initials
                                        newPenPal.image = contact.thumbnailImageData
                                        newPenPal.lastEventType = EventType.noEvent
                                        do {
                                            try moc.save()
                                            UserDefaults.shared.setContactID(for: newPenPal, to: contact.identifier)
                                            presentationMode.wrappedValue.dismiss()
                                        } catch {
                                            dataLogger.error("Could not save PenPal: \(error.localizedDescription)")
                                        }
                                    }
                                }) {
                                    HStack {
                                        if let image = contact.image {
                                            image
                                                .clipShape(Circle())
                                                .frame(width: 40, height: 40)
                                        } else {
                                            ZStack {
                                                Circle()
                                                    .fill(.gray)
                                                Text(contact.initials)
                                                    .font(.system(.headline, design: .rounded))
                                                    .foregroundColor(.white)
                                            }
                                            .frame(width: 40, height: 40)
                                        }
                                        if let name = contact.fullName {
                                            Text(name)
                                        } else {
                                            Text("Unknown Contact")
                                        }
                                    }
                                    .foregroundColor(.primary)
                                }
                            }
                        }
                    }
                    .searchable(text: $searchText)
                } else {
                    VStack {
                        Spacer()
                        if contactsAccessStatus != .authorized {
                            ContactsAccessRequiredView(contactsAccessStatus: $contactsAccessStatus, alwaysShowImage: true)
                        } else {
                            if contactsFetched {
                                if let image = UIImage(named: "undraw_reading_list_re_bk72") {
                                    Image(uiImage: image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(maxWidth: 200)
                                        .padding(.bottom)
                                    if existingPenPals.isEmpty {
                                        Text("You don't appear to have any contacts!")
                                            .fullWidth(alignment: .center)
                                    } else {
                                        Text("Holy prolific writer, Batman!\nYou've added all your contacts as Pen Pals already!")
                                            .fullWidth(alignment: .center)
                                    }
                                }
                            } else {
                                ProgressView()
                            }
                        }
                        Spacer()
                        Button(action: {
                            self.presentingManualAddPenPalSheet = true
                        }) {
                            Text("Add Pen Pal Manually")
                        }
                        Spacer()
                    }
                    .padding()
                }
            }
            .onAppear {
                self.existingPenPalIdentifiers = Set(existingPenPals.compactMap { UserDefaults.shared.getContactID(for: $0) })
                self.contactsAccessStatus = CNContactStore.authorizationStatus(for: .contacts)
            }
            .task {
                if self.contactsAccessStatus == .authorized {
                    let store = CNContactStore()
                    let keys = [
                        CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
                        CNContactFormatter.descriptorForRequiredKeysForNameOrder,
                        CNContactOrganizationNameKey,
                        CNContactImageDataAvailableKey,
                        CNContactThumbnailImageDataKey
                    ] as! [CNKeyDescriptor]
                    let request = CNContactFetchRequest(keysToFetch: keys)
                    request.sortOrder = CNContactsUserDefaults.shared().sortOrder
                    DispatchQueue.global(qos: .userInitiated).async {
                        do {
                            try store.enumerateContacts(with: request) { (contact, stop) in
                                if !existingPenPalIdentifiers.contains(contact.identifier) {
                                    DispatchQueue.main.async {
                                        self.contactDetails.append(contact)
                                    }
                                }
                            }
                            DispatchQueue.main.async {
                                self.contactsFetched = true
                            }
                        } catch {
                            dataLogger.error("Could not enumerate contacts: \(error.localizedDescription)")
                        }
                    }
                }
            }
            .navigationBarTitle("Add Pen Pal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Cancel")
                    }
                }
            }
            .onChange(of: contactsFetched) { _ in
                self.filterContacts()
            }
            .onChange(of: searchText) { searchText in
                self.filterContacts(with: searchText)
            }
        }
        .sheet(isPresented: $presentingManualAddPenPalSheet) {
            ManualAddPenPalSheet() {
                self.presentingManualAddPenPalSheet = false
                self.presentationMode.wrappedValue.dismiss()
            }
        }
    }
    
    func filterContacts(with searchText: String = "") {
        let st = searchText.lowercased()
        withAnimation {
            self.filteredContacts = contactDetails.filter { contact in
                if contact.fullName == nil {
                    return false
                }
                if st.isEmpty {
                    return true
                }
                return contact.matches(term: st)
            }
        }
    }
    
}
