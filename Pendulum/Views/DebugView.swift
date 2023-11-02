//
//  DebugView.swift
//  Pendulum
//
//  Created by Ben Cardy on 02/11/2023.
//

import SwiftUI

struct DebugView: View {
    
    @Environment(\.managedObjectContext) var moc
    
    
    @AppStorage(UserDefaults.Key.hasPerformedCoreDataMigrationToAppGroup.rawValue, store: UserDefaults.shared) private var hasPerformedCoreDataMigrationToAppGroup: Bool = false
    
    @State private var penpalCount: Int = 0
    @State private var eventCount: Int = 0
    @State private var stationeryCount: Int = 0
    @State private var photoCount: Int = 0
    
    var body: some View {
        Form {
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
        self.penpalCount = PenPal.fetch(from: moc).count
        self.eventCount = Event.fetch(from: moc).count
        self.stationeryCount = Stationery.fetch(from: moc).count
        self.photoCount = EventPhoto.fetch(from: moc).count
    }
    
}
