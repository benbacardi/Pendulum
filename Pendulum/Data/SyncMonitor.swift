//
//  SyncMonitor.swift
//  Pendulum
//
//  Created by Ben Cardy on 24/03/2024.
//

import Combine
import CoreData

struct SyncEvent {
    var type: NSPersistentCloudKitContainer.EventType
    var startDate: Date
    var endDate: Date?
    var succeeded: Bool
    var error: Error?
    
    init(from cloudKitEvent: NSPersistentCloudKitContainer.Event) {
        self.type = cloudKitEvent.type
        self.startDate = cloudKitEvent.startDate
        self.endDate = cloudKitEvent.endDate
        self.succeeded = cloudKitEvent.succeeded
        self.error = cloudKitEvent.error
    }
}

enum SyncState {
    case notStarted
    case inProgress(started: Date)
    case succeeded(started: Date, ended: Date)
    case failed(started: Date, ended: Date, error: Error?)
}

class SyncMonitor: ObservableObject {
    
    public static let shared = SyncMonitor()
    
    private var disposables = Set<AnyCancellable>()
    
    @Published private(set) var state: SyncState = .notStarted
    
    init() {
        if #available(iOS 14.0, macCatalyst 14.0, *) {
            NotificationCenter.default.publisher(for: NSPersistentCloudKitContainer.eventChangedNotification)
                .sink(receiveValue: { notification in
                    if let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey] as? NSPersistentCloudKitContainer.Event {
                        DispatchQueue.main.async {
                            self.handle(event: event)
                        }
                    }
                })
                .store(in: &disposables)
        }
    }
    
    func handle(event: NSPersistentCloudKitContainer.Event) {
        cloudKitLogger.debug("Handling event \(event.identifier) for \(event.storeIdentifier)")
        self.handle(event: SyncEvent(from: event))
    }
    
    func handle(event: SyncEvent) {
        var syncState: SyncState = .notStarted
        if let endDate = event.endDate {
            if event.succeeded {
                cloudKitLogger.debug("Sync succeeded: \(event.startDate) to \(endDate)")
                syncState = .succeeded(started: event.startDate, ended: endDate)
            } else {
                cloudKitLogger.debug("Sync failed: \(event.startDate) to \(endDate)")
                syncState = .failed(started: event.startDate, ended: endDate, error: event.error)
            }
        } else {
            cloudKitLogger.debug("Sync started: \(event.startDate)")
            syncState = .inProgress(started: event.startDate)
        }
        self.state = syncState
    }
    
}
