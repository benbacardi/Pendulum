//
//  WidgetData+write.swift
//  Pendulum
//
//  Created by Ben Cardy on 10/01/2023.
//

import Foundation
import WidgetKit

extension WidgetData {
    
    static func fromDatabase() -> WidgetData {
        WidgetData(toSendCount: PenPal.fetch(withStatus: .written).count, toWriteBack: PenPal.fetch(withStatus: .received).map { WidgetDataPerson(id: $0.id ?? UUID(), name: $0.wrappedName, lastEventDate: $0.lastEventDate)})
    }
    
    static func write() {
        guard let filePath = Self.getFilePath() else { return }
        let widgetData = Self.fromDatabase()
        do {
            appLogger.debug("Writing Widget Data: \(widgetData.debugDescription)")
            let data = try JSONEncoder().encode(widgetData)
            try data.write(to: filePath)
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            appLogger.debug("Could not encode widget data to file: \(error.localizedDescription)")
            return
        }
    }
    
}
