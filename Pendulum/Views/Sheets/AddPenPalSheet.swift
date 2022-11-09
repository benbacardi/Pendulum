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
    @Environment(\.presentationMode) var presentationMode
    
    // MARK: State
    let existingPenPals: [PenPal]
    @State private var existingPenPalIdentifiers: Set<String> = []
    @State private var contactDetails: [CNContact] = []
    @State private var contactsFetched: Bool = false
    @State private var sortedContacts: [CNContact] = []
    @State private var searchText: String = ""
    
    var body: some View {
        NavigationStack {
            Group {
                if !contactDetails.isEmpty {
                    List {
                        ForEach(sortedContacts, id: \.identifier) { contact in
                            if !existingPenPalIdentifiers.contains(contact.identifier) {
                                Button(action: {
                                    Task {
                                        let newPenPal = PenPal(id: contact.identifier, name: contact.fullName ?? "Unknown Contact", initials: contact.initials, image: contact.thumbnailImageData, _lastEventType: EventType.noEvent.rawValue, lastEventDate: nil, notes: nil)
                                        do {
                                            try await AppDatabase.shared.save(newPenPal)
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
                                    Text("You've added all your contacts as Pen Pals already!")
                                        .fullWidth(alignment: .center)
                                }
                            }
                        } else {
                            ProgressView()
                        }
                        Spacer()
                    }
                    .padding()
                }
            }
            .onAppear {
                self.existingPenPalIdentifiers = Set(existingPenPals.map { $0.id })
                Task {
                    let store = CNContactStore()
                    let keys = [
                        CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
                        CNContactOrganizationNameKey,
                        CNContactImageDataAvailableKey,
                        CNContactThumbnailImageDataKey
                    ] as! [CNKeyDescriptor]
                    let request = CNContactFetchRequest(keysToFetch: keys)
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Cancel")
                    }
                }
            }
            .onChange(of: contactsFetched) { _ in
                self.sortAndFilterContacts()
            }
            .onChange(of: searchText) { searchText in
                self.sortAndFilterContacts(with: searchText)
            }
        }
    }
    
    func sortAndFilterContacts(with searchText: String = "") {
        let st = searchText.lowercased()
        withAnimation {
            self.sortedContacts = contactDetails.filter { contact in
                if contact.fullName == nil {
                    return false
                }
                if st.isEmpty {
                    return true
                }
                return contact.matches(term: st)
            }.sorted { c1, c2 in
                return c1.sortKey < c2.sortKey
            }
        }
    }
    
}

struct AddPenPalSheet_Previews: PreviewProvider {
    static var previews: some View {
        AddPenPalSheet(existingPenPals: [])
    }
}
