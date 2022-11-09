//
//  SettingsList.swift
//  Pendulum
//
//  Created by Alex Faber on 05/11/2022.
//

import SwiftUI

struct SettingsList: View {
    
    // MARK: Environment
    @Environment(\.openURL) private var openURL
    
    // MARK: State
    @AppStorage(UserDefaults.Key.sendRemindersToWriteLetters.rawValue, store: UserDefaults.shared) private var sendRemindersToWriteLetters: Bool = false
    @AppStorage(UserDefaults.Key.sendRemindersToPostLetters.rawValue, store: UserDefaults.shared) private var sendRemindersToPostLetters: Bool = false
    @AppStorage(UserDefaults.Key.badgeRemindersToWriteLetters.rawValue, store: UserDefaults.shared) private var badgeRemindersToWriteLetters: Bool = false
    @AppStorage(UserDefaults.Key.badgeRemindersToPostLetters.rawValue, store: UserDefaults.shared) private var badgeRemindersToPostLetters: Bool = false
    
    @State private var notificationsAuthorizationStatus: UNAuthorizationStatus = .notDetermined
    
    var someNotificationAccessRequired: Bool {
        sendRemindersToPostLetters || sendRemindersToWriteLetters || badgeRemindersToPostLetters || badgeRemindersToWriteLetters
    }
    
    var body: some View {
        NavigationView {
            Form {
                
                if notificationsAuthorizationStatus == .denied && someNotificationAccessRequired {
                    Section {
                        Button(role: .destructive, action: {
                            if let url = UIApplication.systemSettingsURL {
                                openURL(url)
                            }
                        }) {
                            HStack {
                                Image(systemName: "exclamationmark.octagon.fill")
                                Text("Enable notifications in Settings")
                                    .fullWidth()
                            }
                        }
                    }
                }
                
                Section(
                    header: Text("Notifications"),
                    footer: Text("Reminders will be sent seven days after you receive a letter, and three days after you've written back but not yet posted the response.")
                ) {
                    Toggle("Remind me to write back", isOn: $sendRemindersToWriteLetters.animation())
                    Toggle("Remind me to post letters", isOn: $sendRemindersToPostLetters.animation())
                }
                
                Section(header: Text("Icon Badges")) {
                    Toggle("Show for unwritten responses", isOn: $badgeRemindersToWriteLetters.animation())
                    Toggle("Show for unposted letters", isOn: $badgeRemindersToPostLetters.animation())
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
                    Link(destination: URL(string: "mailto:pendulum@bencardy.co.uk")!) {
                        Text("Send Feedback")
                            .foregroundColor(.primary)
                    }
                }
            }
            .navigationTitle(Text("Settings"))
            .onAppear {
                Task {
                    let center = UNUserNotificationCenter.current()
                    let notificationSettings = await center.notificationSettings()
                    DispatchQueue.main.async {
                        withAnimation {
                            self.notificationsAuthorizationStatus = notificationSettings.authorizationStatus
                        }
                    }
                }
            }
            .onChange(of: sendRemindersToWriteLetters) { newValue in
                if newValue {
                    requestNotificationAccess()
                }
            }
            .onChange(of: sendRemindersToPostLetters) { newValue in
                if newValue {
                    requestNotificationAccess()
                }
            }
            .onChange(of: badgeRemindersToWriteLetters) { newValue in
                if newValue {
                    requestNotificationAccess()
                }
            }
            .onChange(of: badgeRemindersToPostLetters) { newValue in
                if newValue {
                    requestNotificationAccess()
                }
            }
        }
    }
    
    func requestNotificationAccess() {
        Task {
            let center = UNUserNotificationCenter.current()
            do {
                let response = try await center.requestAuthorization(options: [.badge, .sound, .alert])
                DispatchQueue.main.async {
                    withAnimation {
                        self.notificationsAuthorizationStatus = response ? .authorized : .denied
                    }
                }
            } catch {
                appLogger.error("Could not request notification permissions.")
            }
        }
    }
    
}

struct SettingsList_Previews: PreviewProvider {
    static var previews: some View {
        SettingsList()
    }
}

