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
    @State private var displayImage: Image?
    @State private var subHeader: String? = nil
    
    var isSelectedInPath: Bool {
        if DeviceType.isPhone() {
            return false
        } else {
            for path in router.path {
                switch path {
                case .penPalDetail(let pathPenPal):
                    if pathPenPal == penpal {
                        return true
                    }
                default:
                    continue
                }
            }
            return false
        }
    }
    
    @ViewBuilder
    var content: some View {
        HStack {
            if let displayImage {
                displayImage
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
                .task { displayImage = await penpal.displayImage }
            }
            VStack {
                Text(penpal.wrappedName)
                    .font(.headline)
                    .fullWidth()
                if let subHeader {
                    Text(subHeader)
                        .font(.caption)
                        .fullWidth()
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
        .foregroundColor(isSelectedInPath ? .black : .primary)
        .task {
            withAnimation {
                if !penpal.archived && asListItem {
                    if penpal.groupingEventType == .nothingToDo, let lastEvent = penpal.getLastEvent(includingIgnoredEvents: true, from: moc) {
                        self.subHeader = "\(lastEvent.type.datePrefix(for: lastEvent.letterType)) \(Calendar.current.verboseNumberOfDaysBetween(lastEvent.wrappedDate, and: Date()))"
                    } else if let lastEventDate = penpal.lastEventDate {
                        self.subHeader = "\(penpal.lastEventType.datePrefix(for: penpal.lastEventLetterType)) \(Calendar.current.verboseNumberOfDaysBetween(lastEventDate, and: Date()))"
                    }
                }
            }
        }
    }
        
    var body: some View {
        if asListItem {
            VStack {
                content
            }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(Color.accentColor, lineWidth: isSelectedInPath ? 2 : 0)
                    .background {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color(uiColor: .secondarySystemBackground))
                    }
            }
            .backgroundStyle(isSelectedInPath ? Color.accentColor : Color(uiColor: .secondarySystemBackground))
            .opacity(penpal.archived ? 0.5 : 1)
        } else {
            content
        }
    }
}
