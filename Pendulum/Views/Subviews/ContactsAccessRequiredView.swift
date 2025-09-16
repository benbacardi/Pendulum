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
    
    @State private var presentInfoSheet: Bool = false
    
    // MARK: Parameters
    var reason: String = "so you can choose your Pen Pals and quickly pull up their addresses when you need them."
    var alwaysShowImage: Bool = false
    
    var body: some View {
        Group {
            if let image = UIImage(named: "undraw_directions_re_kjxs") {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 200)
                    .padding(.bottom)
            }
            Text("Pendulum works best if you allow access to your contacts \(reason)")
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            if contactsAccessStatus == .denied || contactsAccessStatus == .restricted {
                if #available(iOS 26, *) {
                    Button(action: openSettings) {
                        Text("Enable Contacts Access in Settings")
                    }
                    .foregroundStyle(.white)
                    .buttonStyle(.glass(.regular.tint(.accentColor)))
                } else {
                    Button(action: openSettings) {
                        Text("Enable contacts access in Settings")
                    }
                }
            } else {
                if #available(iOS 26, *) {
                    Button(action: grantAccess) {
                        Text("Grant Contacts Access")
                    }
                    .foregroundStyle(.white)
                    .buttonStyle(.glass(.regular.tint(.accentColor)))
                } else {
                    Button(action: grantAccess) {
                        Text("Grant contacts access")
                    }
                }
            }
            
            Button(action: {
                self.presentInfoSheet = true
            }) {
                Text("What does Pendulum do with my contacts information?")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding([.top, .horizontal])
            
        }
        .sheet(isPresented: $presentInfoSheet) {
            ScrollView {
                if #available(iOS 26, *) {
                    VStack {
                        infoSheetContent
                    }
                    .padding(.top)
                    .padding()
                } else {
                    GroupBox {
                        infoSheetContent
                    }
                    .padding()
                }
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        
    }
    
    @ViewBuilder
    var infoSheetContent: some View {
        Text("Contacts Access")
            .fullWidth()
            .font(.headline)
            .padding(.bottom, 8)
        VStack(spacing: 10) {
            Text("Pendulum does not collect any data about you or your device.")
                .fullWidth()
            Text("Synced data uses private Apple-provided services that we have no access to, and only the name and profile picture of each contact you add is synced in this way. This data is not accessible to anybody other than you.")
                .fullWidth()
            Text("All other information about your contacts stays local to your device, and **no** data is available to anybody other than you.")
                .fullWidth()
            Text("You can turn off Contacts integration in Pendulum Settings to avoid seeing the prompts to grant access in future.")
                .fullWidth()
        }
        .foregroundColor(.secondary)
        .padding(.bottom, 8)
        if #available(iOS 26, *) {
            Button(action: {
                presentInfoSheet = false
            }) {
                Text("Got it!")
            }
            .buttonStyle(.glass)
        } else {
            Button(action: {
                presentInfoSheet = false
            }) {
                Text("Got it!")
            }
        }
    }
    
    func openSettings() {
        if let url = UIApplication.systemSettingsURL {
            openURL(url)
        }
    }
    
    func grantAccess() {
        Task {
            let store = CNContactStore()
            do {
                let result = try await store.requestAccess(for: .contacts)
                if result {
                    self.contactsAccessStatus = .authorized
                } else {
                    self.contactsAccessStatus = .denied
                    UserDefaults.shared.stopAskingAboutContacts = true
                }
            } catch {
                appLogger.debug("Could not request contacts access: \(error.localizedDescription)")
                self.contactsAccessStatus = .denied
                UserDefaults.shared.stopAskingAboutContacts = true
            }
        }
    }
    
}

struct ContactsAccessRequiredView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ContactsAccessRequiredView(contactsAccessStatus: .constant(.notDetermined))
        }
    }
}
