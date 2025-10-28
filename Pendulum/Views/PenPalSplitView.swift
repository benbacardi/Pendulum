//
//  PenPalSplitView.swift
//  Pendulum
//
//  Created by Ben Cardy on 01/03/2023.
//

import SwiftUI
import Contacts

struct PenPalSplitView: View {
    
    // MARK: State
    @StateObject private var router = Router()
    @State private var contactsAccessStatus: CNAuthorizationStatus = .notDetermined
    @AppStorage(UserDefaults.Key.stopAskingAboutContacts, store: UserDefaults.shared) private var stopAskingAboutContacts: Bool = false
    @FetchRequest(sortDescriptors: []) private var allPenPals: FetchedResults<PenPal>
    
    @Namespace private var transition
    
    var navBarDisplayMode: NavigationBarItem.TitleDisplayMode {
        if #available(iOS 26, *) {
            return .inline
        }
        return .large
    }
    
    var navBarTitle: String {
        if #available(iOS 26, *) {
            return ""
        }
        return "Pendulum"
    }
    
    var body: some View {
        SplitView {
            NavigationStack {
                PenPalList()
                    .navigationTitle(navBarTitle)
                    .navigationBarTitleDisplayMode(navBarDisplayMode)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(action: {
                                router.presentedSheet = .settings(namespace: transition)
                            }) {
                                Label("Settings", systemImage: "gear")
                            }
                        }
                        .matchedTransitionSourceIfPossible(id: "settings", in: transition)
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
                    .withSheetDestinations(sheetDestination: $router.presentedSheet)
            }
        } content: {
            NavigationStack {
                if let destination = router.path.first {
                    destination.view
                    .onAppear {
                        appLogger.debug("Destination appeared!")
                    }
                } else {
                    if contactsAccessStatus != .authorized && allPenPals.isEmpty {
                        GrantContactsAccessView(contactsAccessStatus: $contactsAccessStatus)
                    } else if allPenPals.isEmpty {
                        AddFirstPenPalView()
                    } else {
                        VStack {
                            Spacer()
                            if let image = UIImage(named: "undraw_just_saying_re_kw9c") {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxWidth: 200)
                                    .padding(.bottom)
                            }
                            Text("No Pen Pal Selected")
                            Spacer()
                        }
                    }
                }
            }
        }
        .onAppear {
            self.contactsAccessStatus = CNContactStore.authorizationStatus(for: .contacts)
        }
        .environmentObject(router)
    }
}
