//
//  SettingsList.swift
//  Pendulum
//
//  Created by Alex Faber on 05/11/2022.
//

import UIKit
import SwiftUI
import CoreMotion
import SafariServices

struct SafariView: UIViewControllerRepresentable {

    let url: URL

    func makeUIViewController(context: UIViewControllerRepresentableContext<SafariView>) -> SFSafariViewController {
        let controller = SFSafariViewController(url: url)
        controller.preferredControlTintColor = UIColor(Color.accentColor)
        return controller
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: UIViewControllerRepresentableContext<SafariView>) {
    }

}

struct SettingsList: View {
    
    // MARK: Environment
    @Environment(\.openURL) private var openURL
    @EnvironmentObject var appPreferences: AppPreferences
    
    let motionManager = CMMotionManager()
    
    // MARK: State
    @AppStorage(UserDefaults.Key.sendRemindersToWriteLetters.rawValue, store: UserDefaults.shared) private var sendRemindersToWriteLetters: Bool = false
    @AppStorage(UserDefaults.Key.sendRemindersToPostLetters.rawValue, store: UserDefaults.shared) private var sendRemindersToPostLetters: Bool = false
    @AppStorage(UserDefaults.Key.badgeRemindersToWriteLetters.rawValue, store: UserDefaults.shared) private var badgeRemindersToWriteLetters: Bool = false
    @AppStorage(UserDefaults.Key.badgeRemindersToPostLetters.rawValue, store: UserDefaults.shared) private var badgeRemindersToPostLetters: Bool = false
    @AppStorage(UserDefaults.Key.enableQuickEntry.rawValue, store: UserDefaults.shared) private var enableQuickEntry: Bool = false
    @AppStorage(UserDefaults.Key.stopAskingAboutContacts.rawValue, store: UserDefaults.shared) private var stopAskingAboutContacts: Bool = false
    @AppStorage(UserDefaults.Key.sortPenPalsAlphabetically.rawValue, store: UserDefaults.shared) private var sortPenPalsAlphabetically: Bool = false
    
    @State private var sendRemindersToPostLettersDate: Date = Date()
    @State private var notificationsAuthorizationStatus: UNAuthorizationStatus = .notDetermined
    @State private var showStatsLink: Bool = false
    @State private var showFAQs: Bool = false
    
    @State private var angle: Double = 0
    
    var rotationAngle: Double {
        if angle < -9 {
            return -9
        }
        if angle > 9 {
            return 9
        }
        return angle
    }
    
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
                    header: HStack {
                        Image(systemName: "bell")
                        Text("Notifications")
                        Spacer()
                    },
                    footer: Text("Reminders will be sent seven days after you receive a letter, and daily at the specified time after you've written back but not yet posted the response.")
                ) {
                    Toggle("Remind me to write back", isOn: $sendRemindersToWriteLetters.animation())
                    Toggle("Remind me to post letters", isOn: $sendRemindersToPostLetters.animation())
                        .disabled(!appPreferences.trackPostingLetters)
                        .foregroundColor(appPreferences.trackPostingLetters ? .primary : .secondary)
                    if sendRemindersToPostLetters {
                        HStack {
                            Image(systemName: "arrow.turn.down.right")
                            DatePicker("Send reminders daily at", selection: $sendRemindersToPostLettersDate, displayedComponents: [.hourAndMinute])
                                .disabled(!appPreferences.trackPostingLetters)
                        }
                        .padding(.leading, 4)
                        .foregroundColor(appPreferences.trackPostingLetters ? .primary : .secondary)
                    }
                }
                
                Section(header: HStack {
                    Image(systemName: "app.badge")
                    Text("Icon Badges")
                    Spacer()
                }) {
                    Toggle("Show for unwritten responses", isOn: $badgeRemindersToWriteLetters.animation())
                    Toggle("Show for unposted letters", isOn: $badgeRemindersToPostLetters.animation())
                        .disabled(!appPreferences.trackPostingLetters)
                        .foregroundColor(appPreferences.trackPostingLetters ? .primary : .secondary)
                }
                
                Section {
                    NavigationLink(destination: StatsView()) {
                        Text("Statistics")
                    }
                    .disabled(!showStatsLink)
                }

                Section(footer: Text("With Quick Entry, you won't be prompted for notes when logging a written or sent letter. You can add those later by tapping on the entry.")) {
                    Toggle("Track posting letters", isOn: $appPreferences.trackPostingLetters)
                    Toggle("Sort Pen Pals alphabetically", isOn: $sortPenPalsAlphabetically)
                    Toggle("Enable Quick Entry", isOn: $enableQuickEntry)
                }

                Section(footer: Text("If you don't store your Pen Pal information in Contacts, Pendulum can stop prompting for access and rely on manual Pen Pal entry.")) {
                    Toggle("Turn off Contacts integration", isOn: $stopAskingAboutContacts)
                }
                
                Section(
                    header: VStack {
                        if let appIcon = UIImage(named: "no-pendulum") {
                            ZStack(alignment: .top) {
                                Image(uiImage: appIcon)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 50, height: 50)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                Image("just-pendulum")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 20, height: 32, alignment: .top)
                                    .offset(y: 2)
                                    .rotationEffect(.degrees(-rotationAngle), anchor: .top)
                            }
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
                    Button(action: {
                        self.showFAQs = true
                    }) {
                        HStack {
                            Text("Get Help")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "questionmark.circle")
                                .foregroundColor(.secondary)
                        }
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
                    NavigationLink(destination: TipJarView()) {
                        Text("Support Pendulum")
                    }
                    HStack {
                        Text("App Version")
                            .fullWidth()
                        Spacer()
                        Text("\(Bundle.main.appVersionNumber) (Build \(Bundle.main.appBuildNumber))")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .sheet(isPresented: $showFAQs) {
                SafariView(url: URL(string: "https://bencardy.co.uk/pendulum/faq.html")!)
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
                UIApplication.shared.updateBadgeNumber()
            }
            .onChange(of: badgeRemindersToPostLetters) { newValue in
                if newValue {
                    requestNotificationAccess()
                }
                UIApplication.shared.updateBadgeNumber()
            }
            .onChange(of: appPreferences.trackPostingLetters) { newValue in
                UIApplication.shared.updateBadgeNumber()
            }
            .tint(.adequatelyGinger)
            .task {
                if motionManager.isDeviceMotionAvailable {
                    motionManager.deviceMotionUpdateInterval = 0.1
                    let queue = OperationQueue()
                    motionManager.startDeviceMotionUpdates(to: queue, withHandler: { motion, error in
                        if let attitude = motion?.attitude {
                            DispatchQueue.main.async {
                                withAnimation {
                                    self.angle = attitude.roll * 180.0/Double.pi
                                }
                            }
                        }
                    })
                }
            }
            .task {
                self.showStatsLink = Event.count() != 0
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

