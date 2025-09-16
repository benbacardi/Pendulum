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
    @AppStorage(UserDefaults.Key.stopAskingAboutContacts, store: UserDefaults.shared) private var stopAskingAboutContacts: Bool = false
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
                Text("Add your first Pen Pal to get started!")
            } else {
                ContactsAccessRequiredView(contactsAccessStatus: $contactsAccessStatus)
            }
            Spacer()
            if #available(iOS 26, *) {
                Button(action: addPenPal) {
                    Text(self.stopAskingAboutContacts ? "Add Pen Pal" : "Add Pen Pal Manually")
                }
                .foregroundStyle(.white)
                .buttonStyle(.glass(.regular.tint(.accentColor)))
            } else {
                Button(action: addPenPal) {
                    Text(self.stopAskingAboutContacts ? "Add Pen Pal" : "Add Pen Pal Manually")
                }
            }
            Spacer()
        }
    }
    
    func addPenPal() {
        router.presentedSheet = .addPenPalManually(namespace: nil) { penpal in
            router.presentedSheet = nil
            router.navigate(to: .penPalDetail(penpal: penpal))
        }
    }
}

struct GrantContactsAccessView_Previews: PreviewProvider {
    static var previews: some View {
        GrantContactsAccessView(contactsAccessStatus: .constant(.denied))
    }
}
