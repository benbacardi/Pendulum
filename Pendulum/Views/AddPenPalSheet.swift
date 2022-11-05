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
    
    var body: some View {
        List {
            ForEach(contactDetails, id: \.identifier) { contact in
                if !existingPenPalIdentifiers.contains(contact.identifier) {
                    Button(action: {
                        Task {
                            let newPenPal = PenPal(id: contact.identifier, givenName: contact.givenName, familyName: contact.familyName, image: contact.imageData)
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
                            Text(contact.fullName)
                        }
                    }
                }
            }
        }
        .onAppear {
            self.existingPenPalIdentifiers = Set(existingPenPals.map { $0.id })
            Task {
                let store = CNContactStore()
                let keys = [
                    CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
                    CNContactPostalAddressesKey,
                    CNContactImageDataAvailableKey,
                    CNContactImageDataKey,
                ] as! [CNKeyDescriptor]
                let request = CNContactFetchRequest(keysToFetch: keys)
                DispatchQueue.global(qos: .userInitiated).async {
                    do {
                        try store.enumerateContacts(with: request) { (contact, stop) in
                            DispatchQueue.main.async {
                                self.contactDetails.append(contact)
                            }
                        }
                    } catch {
                        print("Could not enumerate contacts: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
}

struct AddPenPalSheet_Previews: PreviewProvider {
    static var previews: some View {
        AddPenPalSheet(existingPenPals: [])
    }
}
