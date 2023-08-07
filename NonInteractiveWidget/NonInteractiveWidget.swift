//
//  NonInteractiveWidget.swift
//  NonInteractiveWidget
//
//  Created by Ben Cardy on 01/08/2023.
//

import WidgetKit
import SwiftUI
import CoreData

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> NonInteractiveWidgetEntry {
        ENTRY_POST_ONLY
    }

    func getSnapshot(in context: Context, completion: @escaping (NonInteractiveWidgetEntry) -> ()) {
        completion(NonInteractiveWidgetEntry.getCurrent(for: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        
        let currentDate = Date()
        let entryDate = Calendar.current.date(byAdding: .minute, value: 1, to: currentDate)!
        let entry = NonInteractiveWidgetEntry.getCurrent(for: entryDate)
        
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

struct NonInteractiveWidgetEntry: TimelineEntry {
    let date: Date
    let postCount: Int
    let awaitingReply: [PenPal]
    
    static func getCurrent(for entryDate: Date) -> NonInteractiveWidgetEntry {
        let awaitingReply = PenPal.fetch(withStatus: .received, from: PersistenceController.shared.container.viewContext)
        let toPostCount: Int
        if UserDefaults.shared.trackPostingLetters {
            toPostCount = PenPal.calculateBadgeNumber(toWrite: false, toPost: true)
        } else {
            toPostCount = 0
        }
        appLogger.debug("awaitingReply=\(awaitingReply.count)")
        appLogger.debug("toPostCount=\(toPostCount)")
        return NonInteractiveWidgetEntry(date: entryDate, postCount: toPostCount, awaitingReply: awaitingReply)
    }
    
}

struct NonInteractiveWidgetEntryView: View {
    
    @Environment(\.widgetFamily) var family
    
    var entry: Provider.Entry
    
    let iconSize: CGFloat = 30

    var itemPlural: String {
        entry.postCount == 1 ? "item" : "items"
    }
    
    var penpalPlural: String {
        entry.awaitingReply.count == 1 ? "reply" : "replies"
    }
    
    @ViewBuilder
    var pendulumIcon: some View {
        Image("pendulum-pen-white")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: iconSize)
            .cornerRadius(iconSize / 4)
    }
    
    var body: some View {
        HStack(spacing: 0) {
            if entry.postCount > 0 {
                VStack(spacing: 0) {
                    HStack {
                        HStack {
                            Image(systemName: EventType.written.phraseIcon)
                                .font(.system(size: iconSize * 0.8))
                            Spacer()
                            pendulumIcon
                                .opacity(entry.awaitingReply.isEmpty || family == .systemSmall ? 1 : 0)
                        }
                    }
                    Spacer()
                    HStack {
                        Text("\(entry.postCount)")
                            .font(.system(size: 60, weight: .bold, design: .rounded))
                        Spacer()
                    }
                    .offset(y: 8)
                    Text("\(itemPlural) to post")
                        .fullWidth()
                }
                .padding()
                .foregroundColor(.white)
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .background(
                    LinearGradient(colors: [EventType.written.color, EventType.written.color.darker(by: 10)], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            }
            if !entry.awaitingReply.isEmpty && (family != .systemSmall || entry.postCount == 0) {
                VStack(spacing: 0) {
                    HStack {
                        HStack {
                            Image(systemName: EventType.received.phraseIcon)
                                .font(.system(size: iconSize * 0.8))
                            Spacer()
                            pendulumIcon
                        }
                    }
                    Spacer()
                    HStack {
                        VStack(spacing: 0) {
                            HStack {
                                Text("\(entry.awaitingReply.count)")
                                    .font(.system(size: 60, weight: .bold, design: .rounded))
                                Spacer()
                            }
                            .offset(y: 8)
                            Text("\(penpalPlural) to write")
                                .fullWidth()
                        }
                        if entry.postCount == 0 {
                            VStack(spacing: 2) {
                                Spacer()
                                ForEach(entry.awaitingReply) { penpal in
                                    Text("\(penpal.wrappedName)")
                                        .lineLimit(1)
                                        .fullWidth()
                                    if penpal != entry.awaitingReply.last {
                                        Divider()
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
                .foregroundColor(.white)
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .background(
                    LinearGradient(colors: [EventType.received.color, EventType.received.color.darker(by: 10)], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            }
            if entry.postCount == 0 && entry.awaitingReply.isEmpty {
                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        pendulumIcon
                    }
                    Spacer()
                    Text("Nothing to do")
                        .fullWidth()
                }
                .padding()
                .foregroundColor(.white)
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .background(
                    LinearGradient(colors: [Color.adequatelyGinger, Color.adequatelyGinger.darker(by: 10)], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            }
        }
    }
}

struct NonInteractiveWidget: Widget {
    let kind: String = WidgetType.NonInteractiveWidget.rawValue

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            NonInteractiveWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
    }
}

let ENTRY_POST_ONLY = NonInteractiveWidgetEntry(date: Date(), postCount: 1, awaitingReply: [])
let ENTRY_REPLY_ONLY = NonInteractiveWidgetEntry(date: Date(), postCount: 0, awaitingReply: [PenPal(), PenPal()])
let ENTRY_POST_AND_REPLY = NonInteractiveWidgetEntry(date: Date(), postCount: 2, awaitingReply: [PenPal()])
let ENTRY_EMPTY = NonInteractiveWidgetEntry(date: Date(), postCount: 0, awaitingReply: [])

struct NonInteractiveWidget_Previews: PreviewProvider {
    static var previews: some View {
        NonInteractiveWidgetEntryView(entry: ENTRY_REPLY_ONLY)
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
