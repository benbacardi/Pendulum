//
//  WidgetData.swift
//  Pendulum
//
//  Created by Ben Cardy on 09/01/2023.
//

import Foundation

struct WidgetDataPerson: Codable, Identifiable, Equatable, Hashable {
    let id: UUID
    let name: String
    let lastEventDate: Date?
}

struct WidgetData: Codable, CustomDebugStringConvertible {
    let toSendCount: Int
    let toWriteBack: [WidgetDataPerson]
    
    var debugDescription: String {
        return "WidgetData(toSendCount: \(self.toSendCount), toWriteBack: \(self.toWriteBack))"
    }
    
    static func getFilePath() -> URL? {
        let sharedFileManager = FileManager.default
        guard let sharedContainerFolderURL = sharedFileManager.containerURL(forSecurityApplicationGroupIdentifier: APP_GROUP) else { return nil }
        return sharedContainerFolderURL.appendingPathComponent("widgetData.json")
    }
    
    static func read() -> WidgetData? {
        guard let filePath = Self.getFilePath() else { return nil }
        appLogger.debug("Reading Widget Data")
        do {
            return try JSONDecoder().decode(WidgetData.self, from: Data(contentsOf: filePath))
        } catch {
            appLogger.debug("Could not read widget data from file: \(error.localizedDescription)")
            return nil
        }
    }
    
}
