//
//  EventPhoto+Extensions.swift
//  Pendulum
//
//  Created by Ben Cardy on 27/03/2023.
//

import Foundation
import CoreData
import SwiftUI

extension EventPhoto {
    static let entityName: String = "EventPhoto"
    
    static func from(_ data: Data, in context: NSManagedObjectContext) -> EventPhoto {
        let eventPhoto = EventPhoto(context: context)
        eventPhoto.id = UUID()
        eventPhoto.data = data
        return eventPhoto
    }
    
    static func from(_ image: UIImage, in context: NSManagedObjectContext) -> EventPhoto {
        let eventPhoto = EventPhoto(context: context)
        eventPhoto.id = UUID()
        eventPhoto.data = image.resize(targetSize: CGSize(width: 2000, height: 2000))?.jpegData(compressionQuality: 1.0) ?? Data()
        eventPhoto.thumbnailData = image.resize(targetSize: CGSize(width: 200, height: 200))?.jpegData(compressionQuality: 0.8) ?? Data()
        eventPhoto.dateAdded = Date()
        return eventPhoto
    }
    
    static func fetch(from context: NSManagedObjectContext) -> [EventPhoto] {
        let fetchRequest = NSFetchRequest<EventPhoto>(entityName: EventPhoto.entityName)
        do {
            return try context.fetch(fetchRequest)
        } catch {
            dataLogger.error("Could not fetch event photos: \(error.localizedDescription)")
        }
        return []
    }
    
    func delete(in context: NSManagedObjectContext, saving: Bool = true) {
        context.delete(self)
        if saving {
            PersistenceController.shared.save(context: context)
        }
    }
    
    func uiImage() -> UIImage? {
        guard let data = self.data else { return nil }
        return UIImage(data: data)
    }
    
    func image() -> Image? {
        guard let uiImage = self.uiImage() else { return nil }
        return Image(uiImage: uiImage)
    }
    
    func thumbnail() -> Image? {
        guard let thumbnailData = self.thumbnailData, let uiImage = UIImage(data: thumbnailData) else { return nil }
        return Image(uiImage: uiImage)
    }
    
    func temporaryURL() -> URL? {
        guard let data = self.data else { return nil }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent((id ?? UUID()).uuidString)
            .appendingPathExtension("jpg")
        if !FileManager.default.fileExists(atPath: url.path) {
            try? data.write(to: url)
        }
        return url
    }
    
}

extension EventPhoto {
    static func deleteAll(in context: NSManagedObjectContext) {
        for photo in fetch(from: context) {
            photo.delete(in: context, saving: false)
        }
        PersistenceController.shared.save(context: context)
    }
}
