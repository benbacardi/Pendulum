//
//  PenPal+Notifications.swift
//  Pendulum
//
//  Created by Ben Cardy on 10/11/2022.
//

import Foundation
import UserNotifications

extension PenPal {
    
    /// Delay before sending a notification to write back, in seconds
    /// 7 days = 7 * 24 * 60 * 60
    static let sendWriteBackNotificationDelay: Double = 7 * 24 * 60 * 60
    
    static let shouldPostLettersNotificationIdentifier: String = "shouldPostLetters"
    
    static func cancelAllShouldPostLettersNotifications() {
        appLogger.debug("Removing any pending notifications for \(PenPal.shouldPostLettersNotificationIdentifier)")
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [PenPal.shouldPostLettersNotificationIdentifier])
    }
    
    static func scheduleShouldPostLettersNotification() async {
        PenPal.cancelAllShouldPostLettersNotifications()
        if UserDefaults.shared.sendRemindersToPostLetters == false {
            return
        }
        
        do {
            
            let count = try await AppDatabase.shared.fetchPenPals(withStatus: .written).count
            if count == 0 {
                return
            }
            
            var dateComponents = DateComponents()
            dateComponents.hour = UserDefaults.shared.sendRemindersToPostLettersAtHour
            dateComponents.minute = UserDefaults.shared.sendRemindersToPostLettersAtMinute
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

            let content = UNMutableNotificationContent()
            content.title = "You have letters to post!"
            content.body = "Get on down to the post box…"
            content.sound = UNNotificationSound.default
            
            appLogger.debug("Scheduling notification: \(PenPal.shouldPostLettersNotificationIdentifier) for \(dateComponents)")
            
            let request = UNNotificationRequest(identifier: PenPal.shouldPostLettersNotificationIdentifier, content: content, trigger: trigger)
            try await UNUserNotificationCenter.current().add(request)
            
        } catch {
            dataLogger.error("Could not fetch penpals or schedule notifications: \(error.localizedDescription)")
        }
        
    }
    
    static func cancelAllShouldWriteBackNotifications() async {
        do {
            let notificationIdentifiers = try await AppDatabase.shared.fetchAllPenPals().map { $0.shouldWriteBackNotificationIdentifier }
            appLogger.debug("Removing pending notifications for \(notificationIdentifiers)")
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: notificationIdentifiers)
        } catch {
            dataLogger.error("Could not cancel all notifications: \(error.localizedDescription)")
        }
    }
    
    static func scheduleAllShouldWriteBackNotifications() async {
        do {
            for penpal in try await AppDatabase.shared.fetchPenPals(withStatus: .received) {
                penpal.scheduleShouldWriteBackNotification()
            }
        } catch {
            dataLogger.error("Could not fetch penpals: \(error.localizedDescription)")
        }
    }
    
    func scheduleShouldWriteBackNotification(countingFrom: Date? = nil) {
        
        self.cancelShouldWriteBackNotification()
        if UserDefaults.shared.sendRemindersToWriteLetters == false {
            return
        }
        
        /// Don't schedule the notification if it's going to be in the past
        let sendDate = (countingFrom ?? (self.lastEventDate ?? Date())).addingTimeInterval(PenPal.sendWriteBackNotificationDelay)
        let now = Date()
        let scheduleInterval = sendDate.timeIntervalSince(now)
        
        if scheduleInterval < 0 {
            appLogger.debug("Not scheduling a notification for \(self.shouldWriteBackNotificationIdentifier) - time has past (\(scheduleInterval))")
            return
        }
        
        appLogger.debug("Adding pending notification for \(self.shouldWriteBackNotificationIdentifier) to fire in \(scheduleInterval) at \(sendDate)")
        let content = UNMutableNotificationContent()
        content.title = "Don't forget to write back"
        content.body = "\(self.name) is waiting for your reply!"
        content.sound = UNNotificationSound.default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: scheduleInterval, repeats: false)
        let request = UNNotificationRequest(identifier: self.shouldWriteBackNotificationIdentifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    func cancelShouldWriteBackNotification() {
        appLogger.debug("Removing any pending notifications for \(self.shouldWriteBackNotificationIdentifier)")
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [self.shouldWriteBackNotificationIdentifier])
    }
    
    private var shouldWriteBackNotificationIdentifier: String {
        "\(self.id):shouldWriteBack"
    }
    
}
