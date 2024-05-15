//
//  AddFirstPenPalView.swift
//  Pendulum
//
//  Created by Ben Cardy on 01/03/2023.
//

import SwiftUI

struct AddFirstPenPalView: View {
    
    @EnvironmentObject private var router: Router
    @AppStorage(UserDefaults.Key.stopAskingAboutContacts, store: UserDefaults.shared) private var stopAskingAboutContacts: Bool = false
    
    var body: some View {
        VStack {
            Spacer()
            if let image = UIImage(named: "undraw_just_saying_re_kw9c") {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 200)
                    .padding(.bottom)
            }
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
                Text("Add your first Pen Pal to get started!")
            }
            Spacer()
        }
        .padding()
    }
}
