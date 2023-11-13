//
//  EventType.swift
//  Pendulum
//
//  Created by Ben Cardy on 06/11/2022.
//

import Foundation
import SwiftUI
import Charts

enum EventType: Int, CaseIterable, Identifiable {
    case written = 1
    case received = 2
    case inbound = 3
    case sent = 4
    case theyReceived = 5
    
    case nothingToDo = 90
    case noEvent = 99
    case archived = 100
    
    var id: Int { rawValue }
    
    static func from(_ value: Int16) -> EventType {
        EventType(rawValue: Int(value)) ?? .noEvent
    }
    
    static var actionableCases: [EventType] {
        EventType.allCases.filter { $0 != .noEvent && $0 != .archived && $0 != .nothingToDo }
    }
    
    var predicate: NSPredicate {
        NSPredicate(format: "typeValue = %d", self.rawValue)
    }
    
    var lastPredicate: NSCompoundPredicate {
        var predicates: [NSPredicate] = [
            NSPredicate(format: "archived = %@", NSNumber(value: false))
        ]
        switch self {
        case .archived:
            predicates = [NSPredicate(format: "archived = %@", NSNumber(value: true))]
        case .noEvent:
            predicates.append(NSPredicate(format: "lastEventTypeValue = %i", rawValue))
            predicates.append(NSPredicate(format: "events.@count == 0"))
        case .nothingToDo:
            predicates.append(NSCompoundPredicate(type: .or, subpredicates: [
                NSPredicate(format: "lastEventTypeValue = %i", EventType.noEvent.rawValue),
                NSPredicate(format: "lastEventTypeValue = %i", EventType.nothingToDo.rawValue),
            ]))
            predicates.append(NSPredicate(format: "events.@count > 0"))
        default:
            predicates.append(NSPredicate(format: "lastEventTypeValue = %i", rawValue))
            predicates.append(NSPredicate(format: "archived = %@", NSNumber(value: false)))
        }
        return NSCompoundPredicate(type: .and, subpredicates: predicates)
    }
    
    func replace(_ value: String, for type: LetterType) -> String {
        return value.replacingOccurrences(of: "%TYPE%", with: type.description)
    }
    
    var description: String {
        /// Displayed in places such as the list of historical events for a Pen Pal
        switch self {
        case .noEvent:
            return "Nothing yet"
        case .written:
            return "You wrote a %TYPE%"
        case .sent:
            return "You sent a %TYPE%"
        case .inbound:
            return "They sent a %TYPE%"
        case .received:
            return "You received a %TYPE%"
        case .theyReceived:
            return "They received your %TYPE%"
        case .archived:
            return "Archived"
        case .nothingToDo:
            return "Nothing to do"
        }
    }
    
    func description(for type: LetterType) -> String {
        return self.replace(self.description, for: type)
    }
    
    var color: Color {
        switch self {
        case .noEvent:
            return .pink
        case .written:
            return .teal
        case .sent:
            return .indigo
        case .inbound:
            return .orange
        case .received:
            return .green
        case .theyReceived:
            return .purple
        case .archived:
            return .gray
        case .nothingToDo:
            return .cyan
        }
    }
    
    var icon: String {
        /// Displayed in laces such as the list of historical events for a Pen Pal
        switch self {
        case .noEvent:
            return "hourglass"
        case .written:
            return "pencil.line"
        case .sent:
            return "paperplane"
        case .inbound:
            return "airplane.departure"
        case .received:
            return "envelope"
        case .theyReceived:
            return "airplane.arrival"
        case .archived:
            return "archivebox"
        case .nothingToDo:
            return "face.smiling.fill"
        }
    }
    
    var phrase: String {
        /// Section headers on the Pen Pal list view
        switch self {
        case .noEvent:
            return "Get started!"
        case .written:
            if !UserDefaults.shared.trackPostingLetters {
                return "You're waiting for a response"
            }
            return "You have post to send!"
        case .sent, .theyReceived:
            return "You're waiting for a response"
        case .inbound:
            return "Post is on its way!"
        case .received:
            return "You have post to reply to!"
        case .archived:
            return "Archived"
        case .nothingToDo:
            return "No actions pending"
        }
    }
    
    var phraseIcon: String {
        /// Section headers on the Pen Pal list view
        switch self {
        case .noEvent:
            return "hourglass"
        case .written:
            return "envelope"
        case .sent:
            return "paperplane"
        case .inbound:
            return "box.truck"
        case .received:
            return "pencil.line"
        case .theyReceived:
            return "envelope"
        case .archived:
            return "archivebox"
        case .nothingToDo:
            return "face.smiling.fill"
        }
    }
    
    var datePrefix: String {
        /// Displayed on the Pen Pal list view before the date "2 days ago" etc
        switch self {
        case .noEvent:
            return "N/A"
        case .written:
            return "You wrote to them"
        case .sent:
            return "You posted their %TYPE%"
        case .inbound:
            return "They posted their %TYPE%"
        case .received:
            return "You received their %TYPE%"
        case .theyReceived:
            return "They received your %TYPE%"
        case .archived:
            return "Archived"
        case .nothingToDo:
            return "Nothing to do"
        }
    }
    
    func datePrefix(for type: LetterType) -> String {
        return self.replace(self.datePrefix, for: type)
    }
    
    var actionableText: String {
        /// Displayed on buttons that register an event of this type
        switch self {
        case .noEvent, .nothingToDo:
            return ""
        case .written:
            return "I've written a letter"
        case .sent:
            return "I've posted a letter"
        case .inbound:
            return "A letter is on its way"
        case .received:
            return "I've received a letter"
        case .theyReceived:
            return "They received my letter"
        case .archived:
            return "Archive"
        }
    }
    
    var actionableTextShort: String {
        /// Displayed on buttons that register an event of this type
        switch self {
        case .noEvent, .nothingToDo:
            return ""
        case .written:
            return "Written"
        case .sent:
            return "Sent"
        case .inbound:
            return "Replied"
        case .received:
            return "It's here"
        case .theyReceived:
            return "Arrived"
        case .archived:
            return "Archive"
        }
    }
    
    var nextLogicalEventTypes: [EventType] {
        switch self {
        case .noEvent, .nothingToDo:
            if !UserDefaults.shared.trackPostingLetters {
                return [.written]
            }
            return [.written, .sent]
        case .written:
            if !UserDefaults.shared.trackPostingLetters {
                return [.inbound, .received]
            }
            return [.sent]
        case .sent:
            return [.inbound, .received]
        case .inbound:
            return [.received]
        case .received:
            if !UserDefaults.shared.trackPostingLetters {
                return [.written]
            }
            return [.written, .sent]
        case .theyReceived:
            return [.inbound, .received]
        case .archived:
            if !UserDefaults.shared.trackPostingLetters {
                return [.written]
            }
            return [.written, .sent]
        }
    }
    
    var presentFullNotesSheetByDefault: Bool {
        switch self {
        case .noEvent, .nothingToDo:
            return false
        case .written:
            return true
        case .sent:
            return true
        case .inbound:
            return false
        case .received:
            return false
        case .theyReceived:
            return false
        case .archived:
            return false
        }
    }
    
}

extension EventType: Plottable {
    var primitivePlottable: String {
        switch self {
        case .received:
            return "Received"
        default:
            return actionableTextShort
        }
    }
    init?(primitivePlottable: String) {
        nil
    }
}
