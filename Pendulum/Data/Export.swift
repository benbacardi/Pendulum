//
//  Export.swift
//  Pendulum
//
//  Created by Ben Cardy on 22/11/2022.
//

import Foundation
import CoreData
import ZIPFoundation

struct ExportedPhoto: Codable {
    let id: UUID
//    let data: Data?
    let dateAdded: Date?
//    let thumbnailData: Data?
    
    init(from: EventPhoto) {
        self.id = from.id ?? UUID()
//        self.data = from.data
        self.dateAdded = from.dateAdded
//        self.thumbnailData = from.thumbnailData
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
//    let image: Data?
    
    init(from: PenPal, in context: NSManagedObjectContext) {
        self.id = from.id ?? UUID()
        self.name = from.wrappedName
        self.initials = from.wrappedInitials
        self.notes = from.notes
        self.archived = from.archived
//        self.image = from.image
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
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US")
        dateFormatter.dateFormat = "yyyy-MM-dd"
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
        
        // Create temporary export ZIP file
        let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName).appendingPathExtension("zip")
        print("BEN: \(tmpURL)")
        
        try? FileManager.default.removeItem(at: tmpURL)
        
        // Zip the contents of the directory
        var error: NSError?
        let coordinator = NSFileCoordinator()
        coordinator.coordinate(readingItemAt: directoryURL, options: [.forUploading], error: &error) { zipurl in
            try! FileManager.default.moveItem(at: zipurl, to: tmpURL)
            print("BEN: Zipped!")
        }
        
        // Return the URL of the temporary ZIP file
        return tmpURL
        
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
        var stationeryCount: Int = 0
        var penPalCount: Int = 0
        var eventCount: Int = 0
        var photoCount: Int = 0
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
                print("BEN: import: \(importData)")
                
                stationeryCount = Stationery.restore(importData.stationery, to: context, saving: false)
                
                PersistenceController.shared.save(context: context)
                
            } else {
                print("BEN: No folder inside ZIP file")
            }
            
        }
        return ImportResult(stationeryCount: stationeryCount, penPalCount: penPalCount, eventCount: eventCount, photoCount: photoCount)
    }
    
}
