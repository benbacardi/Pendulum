//
//  EventType.swift
//  Pendulum
//
//  Created by Ben Cardy on 06/11/2022.
//

import Foundation
import SwiftUI

enum EventType: Int, CaseIterable, Identifiable {
    case written = 1
    case received = 2
    case inbound = 3
    case sent = 4
    case theyReceived = 5
    
    case noEvent = 99
    
    var id: Int { rawValue }
    
    static var actionableCases: [EventType] {
        EventType.allCases.filter { $0 != .noEvent }
    }
    
    var description: String {
        /// Displayed in places such as the list of historical events for a Pen Pal
        switch self {
        case .noEvent:
            return "Nothing yet"
        case .written:
            return "You wrote a letter"
        case .sent:
            return "You sent a letter"
        case .inbound:
            return "They sent something"
        case .received:
            return "You received something"
        case .theyReceived:
            return "They received your letter"
        }
    }
    
    var color: Color {
        switch self {
        case .noEvent:
            return .gray
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
            return "box.truck"
        case .received:
            return "envelope"
        case .theyReceived:
            return "airplane.arrival"
        }
    }
    
    var phrase: String {
        /// Section headers on the Pen Pal list view
        switch self {
        case .noEvent:
            return "Get started!"
        case .written:
            return "You have letters to post!"
        case .sent, .theyReceived:
            return "You're waiting for a response"
        case .inbound:
            return "Post is on its way!"
        case .received:
            return "You have letters to reply to!"
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
            return "square.and.arrow.down"
        case .received:
            return "pencil.line"
        case .theyReceived:
            return "envelope"
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
            return "You posted their letter"
        case .inbound:
            return "They posted their letter"
        case .received:
            return "You received their letter"
        case .theyReceived:
            return "They received your letter"
        }
    }
    
    var actionableText: String {
        /// Displayed on buttons that register an event of this type
        switch self {
        case .noEvent:
            return ""
        case .written:
            return "I've written a letter"
        case .sent:
            return "I've posted a letter"
        case .inbound:
            return "Something's on its way"
        case .received:
            return "I've received something"
        case .theyReceived:
            return "They received my letter"
        }
    }
    
    var actionableTextShort: String {
        /// Displayed on buttons that register an event of this type
        switch self {
        case .noEvent:
            return ""
        case .written:
            return "Written"
        case .sent:
            return "Sent"
        case .inbound:
            return "Replied"
        case .received:
            return "Received"
        case .theyReceived:
            return "Arrived"
        }
    }
    
    var nextLogicalEventTypes: [EventType] {
        switch self {
        case .noEvent:
            return [.written, .sent]
        case .written:
            return [.sent]
        case .sent:
            return [.theyReceived, .inbound]
        case .inbound:
            return [.received]
        case .received:
            return [.written, .sent]
        case .theyReceived:
            return [.inbound, .received]
        }
    }
    
}
