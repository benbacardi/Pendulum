//
//  Export.swift
//  Pendulum
//
//  Created by Ben Cardy on 22/11/2022.
//

import Foundation
import AppleArchive
import System
import CoreData
import ZIPFoundation

struct ExportedPhoto: Codable {
    let id: UUID
    let dateAdded: Date?
    
    init(from: EventPhoto) {
        self.id = from.id ?? UUID()
        self.dateAdded = from.dateAdded
    }
    
    func load(fromArchive archiveDirectory: URL) -> Data? {
        do {
            return try Data(contentsOf: archiveDirectory.appendingPathComponent("photo-\(id.uuidString)").appendingPathExtension("png"))
        } catch {
            appLogger.debug("Could not load photo \(id) from archive \(archiveDirectory)")
        }
        return nil
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
    
    init(from: PenPal, in context: NSManagedObjectContext) {
        self.id = from.id ?? UUID()
        self.name = from.wrappedName
        self.initials = from.wrappedInitials
        self.notes = from.notes
        self.archived = from.archived
        self.events = from.events(from: context).map { ExportedEvent(from: $0) }
    }
    
    func loadImage(fromArchive archiveDirectory: URL) -> Data? {
        do {
            return try Data(contentsOf: archiveDirectory.appendingPathComponent("penpal-\(id.uuidString)").appendingPathExtension("png"))
        } catch {
            appLogger.debug("Could not load contact image \(id) from archive \(archiveDirectory)")
        }
        return nil
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
    var context: NSManagedObjectContext? = nil
    
    enum CodingKeys: CodingKey {
        case penpals, stationery
    }
    
    init(from context: NSManagedObjectContext) {
        self.penpals = PenPal.fetchAll(from: context).map { ExportedPenPal(from: $0, in: context) }
        self.stationery = Stationery.fetch(from: context).map { ExportedStationery(from: $0) }
        self.context = context
    }
    
    func asJSON() throws -> Data {
        let encoder = JSONEncoder()
        return try encoder.encode(self)
    }
    
    var name: String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US")
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return "PendulumExport-\(dateFormatter.string(from: .now))"
    }
    
    func export() throws -> URL {
        
        let fileName = name
        
        // Create temporary directory
        let directoryURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        print("BEN: \(directoryURL)")
        try? FileManager.default.removeItem(atPath: directoryURL.path(percentEncoded: false))
        try FileManager.default.createDirectory(atPath: directoryURL.path(percentEncoded: false), withIntermediateDirectories: true)
        
        // Save JSON data
        let jsonFilePath = directoryURL.appendingPathComponent("data").appendingPathExtension("json")
        print("BEN: \(jsonFilePath)")
        let jsonData = try self.asJSON()
        try jsonData.write(to: jsonFilePath)
        
        // Save PenPal photos
        if let context {
            for penpal in PenPal.fetchAll(from: context) {
                guard let id = penpal.id, let imageData = penpal.image else { continue }
                let filepath = directoryURL.appendingPathComponent("penpal-\(id.uuidString)").appendingPathExtension("png")
                try? imageData.write(to: filepath)
            }
            for photo in EventPhoto.fetch(from: context) {
                guard let id = photo.id, let imageData = photo.data else { continue }
                let filepath = directoryURL.appendingPathComponent("photo-\(id.uuidString)").appendingPathExtension("png")
                try? imageData.write(to: filepath)
            }
        }
        
        // Create export ZIP file
        let zipURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first! .appendingPathComponent(fileName).appendingPathExtension("zip")
        try? FileManager.default.removeItem(at: zipURL)
        try FileManager.default.zipItem(at: directoryURL, to: zipURL)
        try? FileManager.default.removeItem(at: directoryURL)
        
        print("BEN: Saved to \(zipURL)")
        
        return zipURL
        
    }
    
    static func restore(from url: URL, to context: NSManagedObjectContext, overwritingExistingData: Bool = false) throws -> ImportResult {
        if url.startAccessingSecurityScopedResource() {
            print("BEN: Got URL: \(url)")
            let temporaryDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("restore")
            print("BEN: Destination: \(temporaryDirectory)")
            try? FileManager.default.removeItem(at: temporaryDirectory)
            
            try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
            try FileManager.default.unzipItem(at: url, to: temporaryDirectory)
            
            if let folderName = try FileManager.default.contentsOfDirectory(atPath: temporaryDirectory.path).first {
                let containingFolder = temporaryDirectory.appendingPathComponent(folderName)
                let dataFile = containingFolder.appendingPathComponent("data").appendingPathExtension("json")
                let decoder = JSONDecoder()
                let importData = try decoder.decode(Self.self, from: Data(contentsOf: dataFile))
                
                let stationeryCount = Stationery.restore(importData.stationery, to: context, saving: false)
                let penpalRestore = PenPal.restore(importData.penpals, to: context, usingArchive: containingFolder, overwritingExistingData: overwritingExistingData, saving: false)
                
                PersistenceController.shared.save(context: context)
                
                return ImportResult(stationeryCount: stationeryCount, penPalCount: penpalRestore.penPalCount, eventCount: penpalRestore.eventCount, photoCount: penpalRestore.photoCount)
                
            } else {
                appLogger.error("No folder found inside ZIP file")
            }
            
        }
        return ImportResult(stationeryCount: 0, penPalCount: 0, eventCount: 0, photoCount: 0)
    }
    
}
