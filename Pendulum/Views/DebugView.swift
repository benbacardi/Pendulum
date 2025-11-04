//
//  DebugView.swift
//  Pendulum
//
//  Created by Ben Cardy on 02/11/2023.
//

import SwiftUI
#if DEBUG
import Contacts
#endif

struct DebugView: View {
    
    @Environment(\.managedObjectContext) var moc
    
    @ObservedObject var syncMonitor = SyncMonitor.shared
    
    @AppStorage(UserDefaults.Key.hasPerformedCoreDataMigrationToAppGroup, store: UserDefaults.shared) private var hasPerformedCoreDataMigrationToAppGroup: Bool = false
    @AppStorage(UserDefaults.Key.lastSyncDate.rawValue) private var lastSyncDate: Date = .distantPast
    
    @State private var penpalCount: Int = 0
    @State private var eventCount: Int = 0
    @State private var stationeryCount: Int = 0
    @State private var photoCount: Int = 0
    
    var body: some View {
        Form {
            #if DEBUG
            Text("You are running an Xcode debug build.")
            Button(action: { Task { await CNContact.addDummyData() } }) {
                Text("Add Contacts")
            }
            Button(action: {
                Task { await PenPal.addDummyData() }
            }) {
                Text("Add PenPals")
            }
            #endif
            Text("\(syncMonitor.state)")
            Toggle(isOn: $hasPerformedCoreDataMigrationToAppGroup) {
                Text("Migration performed?")
            }
            .disabled(true)
            Text(moc.persistentStoreCoordinator!.persistentStores.first!.url!.debugDescription)
                .font(.caption)
            HStack {
                Text("PenPals")
                Spacer()
                Text("\(penpalCount)")
                    .foregroundColor(.secondary)
                Button(action: {
                    PenPal.deleteAll(in: moc)
                    updateCounts()
                }) {
                    Image(systemName: "trash")
                }
            }
            HStack {
                Text("Events")
                Spacer()
                Text("\(eventCount)")
                    .foregroundColor(.secondary)
                Button(action: {
                    Event.deleteAll(in: moc)
                    updateCounts()
                }) {
                    Image(systemName: "trash")
                }
            }
            HStack {
                Text("EventPhotos")
                Spacer()
                Text("\(photoCount)")
                    .foregroundColor(.secondary)
                Button(action: {
                    EventPhoto.deleteAll(in: moc)
                    updateCounts()
                }) {
                    Image(systemName: "trash")
                }
            }
            HStack {
                Text("Stationery")
                Spacer()
                Text("\(stationeryCount)")
                    .foregroundColor(.secondary)
                Button(action: {
                    Stationery.deleteAll(in: moc)
                    updateCounts()
                }) {
                    Image(systemName: "trash")
                }
            }
        }
        .navigationTitle("Debug")
        .task {
            updateCounts()
        }
    }
    
    func updateCounts() {
        self.penpalCount = PenPal.fetchAll(from: moc).count
        self.eventCount = Event.fetch(from: moc).count
        self.stationeryCount = Stationery.fetch(from: moc).count
        self.photoCount = EventPhoto.fetch(from: moc).count
    }
    
}
