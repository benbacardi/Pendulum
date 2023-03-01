//
//  PenPalTab.swift
//  Pendulum
//
//  Created by Ben Cardy on 01/03/2023.
//

import SwiftUI
import Contacts

struct PenPalTab: View {
    
    // MARK: State
    @StateObject var router = Router()
    @State private var contactsAccessStatus: CNAuthorizationStatus = .notDetermined
    @AppStorage(UserDefaults.Key.stopAskingAboutContacts.rawValue, store: UserDefaults.shared) private var stopAskingAboutContacts: Bool = false
    @FetchRequest(sortDescriptors: []) private var allPenPals: FetchedResults<PenPal>
 
    var body: some View {
        NavigationStack(path: $router.path) {
            Group {
                if contactsAccessStatus != .authorized && allPenPals.isEmpty {
                    GrantContactsAccessView(contactsAccessStatus: $contactsAccessStatus)
                } else if allPenPals.isEmpty {
                    AddFirstPenPalView()
                } else {
                    PenPalList()
                }
            }
            .navigationTitle("Pen Pals")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        router.presentedSheet = .stationeryList
                    }) {
                        Label("Stationery", systemImage: "pencil.and.ruler")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        if self.stopAskingAboutContacts {
                            router.presentedSheet = .addPenPalManually { penpal in
                                router.presentedSheet = nil
                                router.navigate(to: .penPalDetail(penpal: penpal))
                            }
                        } else {
                            router.presentedSheet = .addPenPalFromContacts { penpal in
                                router.presentedSheet = nil
                                router.navigate(to: .penPalDetail(penpal: penpal))
                            }
                        }
                    }) {
                        Label("Add Pen Pal", systemImage: "plus.circle")
                    }
                }
            }
            .withAppRouter()
            .withSheetDestinations(sheetDestination: $router.presentedSheet)
        }
        .onAppear {
            self.contactsAccessStatus = CNContactStore.authorizationStatus(for: .contacts)
        }
        .environmentObject(router)
    }
    
}
