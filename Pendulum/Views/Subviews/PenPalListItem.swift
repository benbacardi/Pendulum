//
//  PenPalListItem.swift
//  Pendulum
//
//  Created by Ben Cardy on 23/11/2022.
//

import SwiftUI

struct PenPalListItem: View {
    
    // MARK: Environment
    @EnvironmentObject private var router: Router
    @Environment(\.managedObjectContext) var moc
    
    // MARK: Parameters
    @ObservedObject var penpal: PenPal
    var asListItem: Bool = true
    var subText: String? = nil
    
    @ViewBuilder
    var content: some View {
        HStack {
            if let image = penpal.displayImage {
                image
                    .clipShape(Circle())
                    .frame(width: 40, height: 40)
            } else {
                ZStack {
                    Circle()
                        .fill(.gray)
                    Text(penpal.wrappedInitials)
                        .font(.system(.headline, design: .rounded))
                        .foregroundColor(.white)
                }
                .frame(width: 40, height: 40)
            }
            VStack {
                Text(penpal.wrappedName)
                    .font(.headline)
                    .fullWidth()
                if !penpal.archived && asListItem {
                    if penpal.groupingEventType == .nothingToDo, let lastEvent = penpal.getLastEvent(includingIgnoredEvents: true, from: moc) {
                        Text("\(lastEvent.type.datePrefix(for: lastEvent.letterType)) \(Calendar.current.verboseNumberOfDaysBetween(lastEvent.wrappedDate, and: Date()))")
                            .font(.caption)
                            .fullWidth()
                    } else if let lastEventDate = penpal.lastEventDate {
                        Text("\(penpal.lastEventType.datePrefix(for: penpal.lastEventLetterType)) \(Calendar.current.verboseNumberOfDaysBetween(lastEventDate, and: Date()))")
                            .font(.caption)
                            .fullWidth()
                    }
                }
                if let subText = subText {
                    Text(subText)
                        .font(.caption)
                        .fullWidth()
                }
            }
            if asListItem && !DeviceType.isPad() {
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
        }
        .foregroundColor(.primary)
    }
        
    var body: some View {
        if asListItem {
            GroupBox {
                content
            }
            .opacity(penpal.archived ? 0.5 : 1)
        } else {
            content
        }
    }
}
