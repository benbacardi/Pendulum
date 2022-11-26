//
//  ContactsAccessRequiredView.swift
//  Pendulum
//
//  Created by Ben Cardy on 05/11/2022.
//

import SwiftUI
import Contacts

struct ContactsAccessRequiredView: View {
    
    // MARK: Environment
    @Environment(\.openURL) private var openURL
    
    // MARK: External State
    @Binding var contactsAccessStatus: CNAuthorizationStatus
    
    // MARK: Parameters
    var reason: String = "so you can choose your Pen Pals and quickly pull up their addresses when you need them."
    
    var body: some View {
        Group {
            if !DeviceType.isPad() {
                if let image = UIImage(named: "undraw_directions_re_kjxs") {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 200)
                        .padding(.bottom)
                }
            }
            Text("Pendulum works best if you allow access to your contacts \(reason)")
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            if contactsAccessStatus == .denied || contactsAccessStatus == .restricted {
                Button(action: {
                    if let url = UIApplication.systemSettingsURL {
                        openURL(url)
                    }
                }) {
                    Text("Enable contacts access in Settings")
                }
            } else {
                Button(action: {
                    Task {
                        let store = CNContactStore()
                        do {
                            let result = try await store.requestAccess(for: .contacts)
                            self.contactsAccessStatus = result ? .authorized : .denied
                        } catch {
                            print("Could not request contacts access: \(error.localizedDescription)")
                        }
                    }
                }) {
                    Text("Grant contacts access")
                }
            }
        }
    }
}

struct ContactsAccessRequiredView_Previews: PreviewProvider {
    static var previews: some View {
        ContactsAccessRequiredView(contactsAccessStatus: .constant(.notDetermined))
    }
}
