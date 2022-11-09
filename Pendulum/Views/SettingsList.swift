//
//  SettingsList.swift
//  Pendulum
//
//  Created by Alex Faber on 05/11/2022.
//

import SwiftUI

struct SettingsList: View {
    
    // MARK: State
    @AppStorage(UserDefaults.Key.sendRemindersToWriteLetters.rawValue, store: UserDefaults.shared) private var sendRemindersToWriteLetters: Bool = false
    @AppStorage(UserDefaults.Key.sendRemindersToPostLetters.rawValue, store: UserDefaults.shared) private var sendRemindersToPostLetters: Bool = false
    
    @State private var enableNotifications = false
    @State private var enableEllen = false

    
    var body: some View {
        NavigationView {
            Form {
                Section(
                    header: Text("Notifications"),
                    footer: Text("Reminders will be sent seven days after you receive a letter, and three days after you've written back but not yet posted the response.")
                ) {
                    Toggle("Remind me to write back", isOn: $sendRemindersToWriteLetters)
                    Toggle("Remind me to post letters", isOn: $sendRemindersToPostLetters)
                }
                Section(
                    header: VStack {
                        if let appIcon = UIImage(named: "AppIcon") {
                            Image(uiImage: appIcon)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 50, height: 50)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        Text(Bundle.main.appName)
                            .textCase(nil)
                            .font(.headline)
                    }
                    .padding(.vertical)
                    .fullWidth(alignment: .center),
                    footer: Text("\nA **Faber & Cardy** Production\n\nFor Ellen, adequately ginger, but perfectly lovely")
                        .fullWidth(alignment: .center)
                ) {
                    HStack {
                        Text("App Version")
                            .fullWidth()
                        Spacer()
                        Text("\(Bundle.main.appVersionNumber) (Build \(Bundle.main.appBuildNumber))")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            .navigationTitle(Text("Settings"))
        }
    }
    
}

struct SettingsList_Previews: PreviewProvider {
    static var previews: some View {
        SettingsList()
    }
}

