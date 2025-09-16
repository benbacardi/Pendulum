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
    @AppStorage(UserDefaults.Key.stopAskingAboutContacts, store: UserDefaults.shared) private var stopAskingAboutContacts: Bool = false
    @FetchRequest(sortDescriptors: []) private var allPenPals: FetchedResults<PenPal>
    
    @Namespace private var transition
 
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
                        router.presentedSheet = .stationeryList(namespace: transition)
                    }) {
                        Label("Stationery", systemImage: "pencil.and.ruler")
                    }
                }
                .matchedTransitionSourceIfPossible(id: "stationeryList", in: transition)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        if self.stopAskingAboutContacts {
                            router.presentedSheet = .addPenPalManually(namespace: transition) { penpal in
                                router.presentedSheet = nil
                                router.navigate(to: .penPalDetail(penpal: penpal))
                            }
                        } else {
                            // TODO: fix
                            router.presentedSheet = .addPenPalFromContacts(namespace: transition) { penpal in
                                router.presentedSheet = nil
                                router.navigate(to: .penPalDetail(penpal: penpal))
                            }
                        }
                    }) {
                        Label("Add Pen Pal", systemImage: "plus")
                    }
                }
                .matchedTransitionSourceIfPossible(id: "addPenPal", in: transition)
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
