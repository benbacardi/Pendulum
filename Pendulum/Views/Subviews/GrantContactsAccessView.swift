//
//  GrantContactsAccessView.swift
//  Pendulum
//
//  Created by Ben Cardy on 01/03/2023.
//

import SwiftUI
import Contacts

struct GrantContactsAccessView: View {
    
    @EnvironmentObject private var router: Router
    @AppStorage(UserDefaults.Key.stopAskingAboutContacts.rawValue, store: UserDefaults.shared) private var stopAskingAboutContacts: Bool = false
    @Binding var contactsAccessStatus: CNAuthorizationStatus
    
    var body: some View {
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
                router.presentedSheet = .addPenPalManually { penpal in
                    router.presentedSheet = nil
                    router.navigate(to: .penPalDetail(penpal: penpal))
                }
            }) {
                Text(self.stopAskingAboutContacts ? "Add Pen Pal" : "Add Pen Pal Manually")
            }
            Spacer()
        }
    }
}

struct GrantContactsAccessView_Previews: PreviewProvider {
    static var previews: some View {
        GrantContactsAccessView(contactsAccessStatus: .constant(.denied))
    }
}
