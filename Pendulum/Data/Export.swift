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
}

struct ExportMetadata: Codable {
    let majorVersion: Int
    let minorVersion: Int
    
    static var currentVersion: ExportMetadata {
        initialVersion
    }
    
    static var initialVersion: ExportMetadata {
        ExportMetadata(majorVersion: 1, minorVersion: 0)
    }
}

enum ExportRestoreError: Error {
    case fileSystemError
    case invalidFormat
    case unknownFormat
}

class ExportService {
    let encoder: JSONEncoder
    let decoder: JSONDecoder
    let name: String
    
    init(encoder: JSONEncoder = .init(), decoder: JSONDecoder = .init(), name: String? = nil) {
        self.encoder = encoder
        self.decoder = decoder
        if let name {
            self.name = name
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US")
            dateFormatter.dateFormat = "yyyy-MM-dd"
            self.name =  "PendulumExport-\(dateFormatter.string(from: .now))"
        }
    }
    
    func export(from context: NSManagedObjectContext) throws -> URL {
        // Create temporary directory
        let directoryURL = FileManager.default.temporaryDirectory.appendingPathComponent(self.name)
        appLogger.debug("Temporary export directory: \(directoryURL)")
        try? FileManager.default.removeItem(atPath: directoryURL.path(percentEncoded: false))
        try FileManager.default.createDirectory(atPath: directoryURL.path(percentEncoded: false), withIntermediateDirectories: true)
        
        // Save Metadata 
        let metadataFilePath = directoryURL.appendingPathComponent("metadata").appendingPathExtension("json")
        try self.encoder.encode(ExportMetadata.currentVersion).write(to: metadataFilePath)
        
        // Save JSON data
        let jsonFilePath = directoryURL.appendingPathComponent("data").appendingPathExtension("json")
        appLogger.debug("JSON data file: \(jsonFilePath)")
        
        let penpals = PenPal.fetchAll(from: context).map { ExportedPenPal(from: $0, in: context) }
        let stationery = Stationery.fetch(from: context).map { ExportedStationery(from: $0) }
        
        let exportData = Export(penpals: penpals, stationery: stationery)
        let jsonData = try self.encoder.encode(exportData)
        try jsonData.write(to: jsonFilePath)
        
        // Save PenPal photos
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
        
        // Create export ZIP file
        let zipURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first! .appendingPathComponent(self.name).appendingPathExtension("zip")
        try? FileManager.default.removeItem(at: zipURL)
        try FileManager.default.zipItem(at: directoryURL, to: zipURL)
        try? FileManager.default.removeItem(at: directoryURL)
        
        appLogger.debug("Saved to \(zipURL)")
        
        return zipURL
    }
    
    func restore(from url: URL, to context: NSManagedObjectContext, overwritingExistingData: Bool = false) throws -> ImportResult {
        if url.startAccessingSecurityScopedResource() {
            appLogger.debug("Got URL: \(url)")
            
            let temporaryDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("restore")
            appLogger.debug("Destination: \(temporaryDirectory)")
            try? FileManager.default.removeItem(at: temporaryDirectory)
            
            do {
                try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
            } catch {
                throw ExportRestoreError.fileSystemError
            }
            
            do {
                try FileManager.default.unzipItem(at: url, to: temporaryDirectory)
            } catch {
                throw ExportRestoreError.invalidFormat
            }
            
            if let folderName = try FileManager.default.contentsOfDirectory(atPath: temporaryDirectory.path).first {
                
                let decoder = JSONDecoder()
                
                let containingFolder = temporaryDirectory.appendingPathComponent(folderName)
                
                // Fetch metadata, if it exists
                let metadataFilePath = containingFolder.appendingPathComponent("metadata").appendingPathExtension("json")
                
                let metadata: ExportMetadata
                if !FileManager.default.fileExists(atPath: metadataFilePath.path) {
                    metadata = .initialVersion
                } else {
                    do {
                        metadata = try decoder.decode(ExportMetadata.self, from: Data(contentsOf: metadataFilePath))
                    } catch {
                        appLogger.error("Could not read metadata file")
                        throw ExportRestoreError.invalidFormat
                    }
                }
                
                switch(metadata.majorVersion) {
                    
                case 1:
                    
                    let dataFile = containingFolder.appendingPathComponent("data").appendingPathExtension("json")
                    
                    let importData: Export
                    
                    do {
                        importData = try decoder.decode(Export.self, from: Data(contentsOf: dataFile))
                    } catch {
                        throw ExportRestoreError.invalidFormat
                    }
                    
                    let stationeryCount = Stationery.restore(importData.stationery, to: context, saving: false)
                    let penpalRestore = PenPal.restore(importData.penpals, to: context, usingArchive: containingFolder, overwritingExistingData: overwritingExistingData, saving: false)
                    
                    PersistenceController.shared.save(context: context)
                    
                    return ImportResult(stationeryCount: stationeryCount, penPalCount: penpalRestore.penPalCount, eventCount: penpalRestore.eventCount, photoCount: penpalRestore.photoCount)
                    
                default:
                    throw ExportRestoreError.unknownFormat
                    
                }
                
            } else {
                appLogger.error("No folder found inside ZIP file")
                throw ExportRestoreError.invalidFormat
            }
            
        }
        throw ExportRestoreError.fileSystemError
    }
    
}
