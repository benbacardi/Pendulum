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
    @AppStorage(UserDefaults.Key.enableQuickEntry.rawValue, store: UserDefaults.shared) private var enableQuickEntry: Bool = false
    
    @State private var sendRemindersToPostLettersDate: Date = Date()
    @State private var notificationsAuthorizationStatus: UNAuthorizationStatus = .notDetermined
    
    @State private var generatingExport: Bool = false
    @State private var exportFileURL: URL? = nil
    @State private var showExportFileShareSheet: Bool = false
    
    var someNotificationAccessRequired: Bool {
        sendRemindersToPostLetters || sendRemindersToWriteLetters || badgeRemindersToPostLetters || badgeRemindersToWriteLetters
    }
    
    var body: some View {
        NavigationView {
            Form {
                
                if notificationsAuthorizationStatus == .denied && someNotificationAccessRequired {
                    Section(footer: Text("Without Notification permissions, Pendulum will be unable to send reminders or display an icon badge.")) {
                        Button(role: .destructive, action: {
                            if let url = UIApplication.systemSettingsURL {
                                openURL(url)
                            }
                        }) {
                            HStack {
                                Image(systemName: "exclamationmark.octagon.fill")
                                Text("Enable Notifications in Settings")
                                    .fullWidth()
                            }
                        }
                    }
                }
                
                Section(
                    header: Text("Notifications"),
                    footer: Text("Reminders will be sent seven days after you receive a letter, and daily at the specified time after you've written back but not yet posted the response.")
                ) {
                    Toggle("Remind me to write back", isOn: $sendRemindersToWriteLetters.animation())
                    Toggle("Remind me to post letters", isOn: $sendRemindersToPostLetters.animation())
                    if sendRemindersToPostLetters {
                        HStack {
                            Image(systemName: "arrow.turn.down.right")
                            DatePicker("Send reminders daily at", selection: $sendRemindersToPostLettersDate, displayedComponents: [.hourAndMinute])
                        }
                        .padding(.leading, 4)
                    }
                }
                
                Section(header: Text("Icon Badges")) {
                    Toggle("Show for unwritten responses", isOn: $badgeRemindersToWriteLetters.animation())
                    Toggle("Show for unposted letters", isOn: $badgeRemindersToPostLetters.animation())
                }
                
                Section(footer: Text("With Quick Entry, you won't be prompted for notes when logging a written or sent letter. You can add those later by tapping on the entry.")) {
                    Toggle("Enable Quick Entry", isOn: $enableQuickEntry)
                }
                
                Section {
                    Button(action: {
                        self.generatingExport = true
                        Task {
                            if let url = PersistenceController.shared.exportToFile() {
                                DispatchQueue.main.async {
                                    self.exportFileURL = url
                                    self.showExportFileShareSheet = true
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    self.generatingExport = false
                                }
                            }
                        }
                    }) {
                        HStack {
                            Text("Export Data")
                            Spacer()
                            if self.generatingExport {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(self.generatingExport)
                }
                .sheet(isPresented: $showExportFileShareSheet) {
                    if let exportFileURL = self.exportFileURL {
                        ShareSheetView(activityItems: [exportFileURL])
                    }
                }
                
                Section(
                    header: VStack {
                        if let appIcon = UIImage(named: "pendulum") {
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
                    footer: Text("\nA **Faber & Cardy** Production\n\nFor Ellen; adequately ginger, but perfectly lovely")
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
                        HStack {
                            Text("Send Feedback")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "paperplane")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle(Text("Settings"))
            .task {
                let center = UNUserNotificationCenter.current()
                let notificationSettings = await center.notificationSettings()
                DispatchQueue.main.async {
                    withAnimation {
                        self.notificationsAuthorizationStatus = notificationSettings.authorizationStatus
                    }
                }
            }
            .onAppear {
                var dateComponents = DateComponents()
                dateComponents.hour = UserDefaults.shared.sendRemindersToPostLettersAtHour
                dateComponents.minute = UserDefaults.shared.sendRemindersToPostLettersAtMinute
                self.sendRemindersToPostLettersDate = Calendar.current.date(from: dateComponents) ?? Date()
            }
            .onChange(of: sendRemindersToPostLettersDate) { newValue in
                UserDefaults.shared.sendRemindersToPostLettersAtHour = Calendar.current.component(.hour, from: newValue)
                UserDefaults.shared.sendRemindersToPostLettersAtMinute = Calendar.current.component(.minute, from: newValue)
            }
            .onChange(of: sendRemindersToWriteLetters) { newValue in
                if newValue {
                    requestNotificationAccess()
                    Task {
                        PenPal.scheduleAllShouldWriteBackNotifications()
                    }
                } else {
                    Task {
                        PenPal.cancelAllShouldWriteBackNotifications()
                    }
                }
            }
            .onChange(of: sendRemindersToPostLetters) { newValue in
                if newValue {
                    requestNotificationAccess()
                } else {
                    PenPal.cancelAllShouldPostLettersNotifications()
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
            .tint(.adequatelyGinger)
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

