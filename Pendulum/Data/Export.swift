//
//  Export.swift
//  Pendulum
//
//  Created by Ben Cardy on 22/11/2022.
//

import Foundation
import CoreData

struct ExportedPhoto: Codable {
    let id: UUID
    let data: Data?
    let dateAdded: Date?
    let thumbnailData: Data?
    
    init(from: EventPhoto) {
        self.id = from.id ?? UUID()
        self.data = from.data
        self.dateAdded = from.dateAdded
        self.thumbnailData = from.thumbnailData
    }
    
}

struct ExportedEvent: Codable {
    let id: UUID
    let type: Int
    let letterType: Int
    let date: Date
    let notes: String?
    let pen: String?
    let ink: String?
    let paper: String?
    let trackingReference: String?
    let ignore: Bool
    let photos: [ExportedPhoto]
    
    init(from: Event) {
        self.id = from.id ?? UUID()
        self.type = from.type.rawValue
        self.date = from.wrappedDate
        self.notes = from.notes
        self.pen = from.pen
        self.ink = from.ink
        self.paper = from.paper
        self.trackingReference = from.trackingReference
        self.ignore = from.ignore
        self.letterType = from.letterType.rawValue
        self.photos = from.allPhotos().map { ExportedPhoto(from: $0) }
    }
    
}

struct ExportedPenPal: Codable {
    let id: UUID
    let name: String
    let initials: String
    let notes: String?
    let events: [ExportedEvent]
    let archived: Bool
    let image: Data?
    
    init(from: PenPal, in context: NSManagedObjectContext) {
        self.id = from.id ?? UUID()
        self.name = from.wrappedName
        self.initials = from.wrappedInitials
        self.notes = from.notes
        self.archived = from.archived
        self.image = from.image
        self.events = from.events(from: context).map { ExportedEvent(from: $0) }
    }
    
}

struct ExportedStationery: Codable {
    let id: UUID
    let type: String
    let value: String
    
    init(from: Stationery) {
        self.id = from.id ?? UUID()
        self.type = from.wrappedType
        self.value = from.wrappedValue
    }
    
}

struct ImportResult {
    let stationeryCount: Int
    let penPalCount: Int
    let eventCount: Int
    let photoCount: Int
}

struct Export: Codable {
    let penpals: [ExportedPenPal]
    let stationery: [ExportedStationery]
    
    init(from context: NSManagedObjectContext) {
        self.penpals = PenPal.fetch(from: context).map { ExportedPenPal(from: $0, in: context) }
        self.stationery = Stationery.fetch(from: context).map { ExportedStationery(from: $0) }
    }
    
    func asJSON() throws -> Data {
        let encoder = JSONEncoder()
        return try encoder.encode(self)
    }
    
    static func restore(from data: Data, to context: NSManagedObjectContext) throws -> ImportResult {
        let decoder = JSONDecoder()
        let importData = try decoder.decode(Self.self, from: data)
        let stationeryCount = Stationery.restore(importData.stationery, to: context, saving: false)
        let penpalRestore = PenPal.restore(importData.penpals, to: context, saving: false)
        PersistenceController.shared.save(context: context)
        return ImportResult(stationeryCount: stationeryCount, penPalCount: penpalRestore.penPalCount, eventCount: penpalRestore.eventCount, photoCount: penpalRestore.photoCount)
    }
    
    static func restore(from url: URL, to context: NSManagedObjectContext) throws -> ImportResult {
        if url.startAccessingSecurityScopedResource() {
            return try restore(from: try Data(contentsOf: url), to: context)
        }
        return ImportResult(stationeryCount: 0, penPalCount: 0, eventCount: 0, photoCount: 0)
    }
    
}
