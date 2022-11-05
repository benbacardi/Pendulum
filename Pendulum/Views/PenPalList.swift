//
//  PenPalList.swift
//  Pendulum
//
//  Created by Ben Cardy on 04/11/2022.
//

import SwiftUI
import Contacts
import GRDB

struct PenPalList: View {
    
    // MARK: State
    @StateObject private var penPalListController = PenPalListController()
    @State private var contactsAccessStatus: CNAuthorizationStatus = .notDetermined
    @State private var presentingAddPenPalSheet: Bool = false
    
    var body: some View {
        NavigationStack {
            Group {
                if contactsAccessStatus == .notDetermined || (contactsAccessStatus != .authorized && penPalListController.penpals.isEmpty) {
                    /// Show contacts access required message if it hasn't been requested,
                    /// or it has been denied and the user hasn't added any pen pals yet
                    ContactsAccessRequiredView(contactsAccessStatus: $contactsAccessStatus)
                } else if penPalListController.penpals.isEmpty {
                    VStack {
                        Spacer()
                        Text("Add your first Pen Pal to get started!")
                        Spacer()
                    }
                } else {
                    ScrollView {
                        ForEach(EventType.allCases, id: \.self) { eventType in
                            if penPalListController.groupedPenPals.keys.contains(eventType) {
                                Text("\(eventType.description)")
                                ForEach(penPalListController.groupedPenPals[eventType]!, id: \.self) { penpal in
                                    Text(penpal.fullName)
                                    HStack {
                                        Button(action: {
                                            Task {
                                                await penpal.addEvent(ofType: .written)
                                            }
                                        }) {
                                            Text("Written")
                                        }
                                        Button(action: {
                                            Task {
                                                await penpal.addEvent(ofType: .sent)
                                            }
                                        }) {
                                            Text("Sent")
                                        }
                                        Button(action: {
                                            Task {
                                                await penpal.addEvent(ofType: .inbound)
                                            }
                                        }) {
                                            Text("Inbound")
                                        }
                                        Button(action: {
                                            Task {
                                                await penpal.addEvent(ofType: .received)
                                            }
                                        }) {
                                            Text("Received")
                                        }
                                    }
                                }
                                Divider()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Pen Pals")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        self.presentingAddPenPalSheet = true
                    }) {
                        Label("Add Pen Pal", systemImage: "plus.circle")
                    }
                    .disabled(contactsAccessStatus != .authorized)
                }
            }
            .sheet(isPresented: $presentingAddPenPalSheet) {
                AddPenPalSheet(existingPenPals: penPalListController.penpals)
            }
        }
        .onAppear {
            self.contactsAccessStatus = CNContactStore.authorizationStatus(for: .contacts)
        }
    }
}

struct PenPalList_Previews: PreviewProvider {
    static var previews: some View {
        PenPalList()
    }
}
