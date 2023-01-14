//
//  PendulumWidget.swift
//  PendulumWidget
//
//  Created by Ben Cardy on 09/01/2023.
//

import WidgetKit
import SwiftUI
import Intents

let SAMPLE_WIDGET_DATA = WidgetData(toSendCount: 1, toWriteBack: [
    WidgetDataPerson(id: UUID(), name: "Ben Cardy", lastEventDate: Date()),
    WidgetDataPerson(id: UUID(), name: "Alex Faber", lastEventDate: Date().addingTimeInterval(-86400))
])

struct Provider: IntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), data: WidgetData.read() ?? SAMPLE_WIDGET_DATA, configuration: ConfigurationIntent())
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), data: WidgetData.read() ?? SAMPLE_WIDGET_DATA, configuration: configuration)
        completion(entry)
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        let entryDate = Calendar.current.date(byAdding: .minute, value: 1, to: currentDate)!
        let data = WidgetData.read()
        print("BEN: \(data.debugDescription)")
        let entry = SimpleEntry(date: entryDate, data: WidgetData.read(), configuration: configuration)
        entries.append(entry)

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let data: WidgetData?
    let configuration: ConfigurationIntent
    
}

struct PendulumWidgetEntryView : View {
    
    @Environment(\.widgetFamily) var widgetFamily
    
    var entry: Provider.Entry
    
    @State private var iconWidth: CGFloat = 20
    
    var maxListLength: Int {
        switch widgetFamily {
        case .systemMedium:
            return 4
        case .systemLarge:
            return 6
        default:
            return 3
        }
    }
    
    var listSpacing: CGFloat {
        switch widgetFamily {
        case .systemMedium:
            return 7
        case .systemLarge:
            return 8
        default:
            return 5
        }
    }
    
    var toWriteBack: [WidgetDataPerson] {
        guard let data = entry.data else { return [] }
        return Array(data.toWriteBack.prefix(maxListLength))
    }
    
    @ViewBuilder
    func penPalList(data: WidgetData) -> some View {
        ForEach(toWriteBack, id: \.self) { penpal in
            HStack {
                Text(penpal.name)
                    .font(widgetFamily == .systemLarge ? .callout : .caption)
                    .fullWidth()
                if widgetFamily == .systemLarge, let date = penpal.lastEventDate {
                    Spacer()
                    Text(Calendar.current.verboseNumberOfDaysBetween(date, and: Date()))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.bottom, listSpacing)
            if penpal != toWriteBack.last {
                Divider()
                    .padding(.bottom, listSpacing)
            }
        }
        if widgetFamily != .systemSmall && data.toWriteBack.count > maxListLength {
            Divider()
            Text("+\(data.toWriteBack.count - maxListLength) more")
                .fullWidth()
                .font(widgetFamily == .systemLarge ? .callout : .caption)
                .foregroundColor(.adequatelyGinger)
                .padding(.top, 6)
        }
    }
    
    @ViewBuilder
    func toReplyIcon(data: WidgetData) -> some View {
        HStack {
            ZStack {
                Circle()
                    .fill(EventType.received.color)
                    .frame(width: iconWidth * 1.5, height: iconWidth * 1.5)
                Image(systemName: EventType.received.phraseIcon)
                    .font(Font.caption.weight(.bold))
                    .foregroundColor(.white)
                    .background(GeometryReader { geo in
                        Color.clear.preference(key: WidgetIconWidthPreferenceKey.self, value: max(geo.size.width, geo.size.height))
                    })
            }
            Text("\(data.toWriteBack.count)")
                .font(.title)
                .fontWeight(.bold)
        }
    }
    
    @ViewBuilder
    func toSendIcon(data: WidgetData) -> some View {
        if data.toSendCount > 0 {
            HStack {
                ZStack {
                    Circle()
                        .fill(EventType.written.color)
                        .frame(width: iconWidth * 1.5, height: iconWidth * 1.5)
                    Image(systemName: EventType.written.phraseIcon)
                        .font(Font.caption.weight(.bold))
                        .foregroundColor(.white)
                        .background(GeometryReader { geo in
                            Color.clear.preference(key: WidgetIconWidthPreferenceKey.self, value: max(geo.size.width, geo.size.height))
                        })
                }
                Text("\(data.toSendCount)")
                    .font(.title)
                    .fontWeight(.bold)
            }
        } else {
            EmptyView()
        }
    }
    
    @ViewBuilder
    var repliesTitle: some View {
        Text("Replies to write")
            .font(widgetFamily == .systemLarge ? .title2 : .callout)
            .fontWeight(.bold)
            .fullWidth()
            .foregroundColor(.adequatelyGinger)
    }

    var body: some View {
        VStack(spacing: 0) {
            if let data = entry.data {
                
                if widgetFamily == .systemMedium {
                    
                    GeometryReader { proxy in
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    toSendIcon(data: data)
                                    Spacer()
                                }
                                Spacer()
                                HStack {
                                    toReplyIcon(data: data)
                                    Spacer()
                                }
                                repliesTitle
                            }
                            .frame(width: proxy.size.width * 0.4)
                            VStack(spacing: 0) {
                                penPalList(data: data)
                                Spacer()
                            }
                        }
                    }
                    .padding()
                    
                } else {
                    
                    VStack(spacing: 0) {
                        HStack(spacing: 0) {
                            toReplyIcon(data: data)
                            Spacer()
                            toSendIcon(data: data)
                        }
                        if widgetFamily != .systemLarge {
                            Spacer()
                        } else {
                            Spacer()
                                .frame(height: 8)
                        }
                        repliesTitle
                        if widgetFamily ==  .systemLarge {
                            Rectangle()
                                .frame(minHeight: 2, maxHeight: 2)
                                .padding(.vertical, 8)
                                .opacity(0.2)
                        }
                        Spacer()
                            .frame(height: 5)
                        if data.toWriteBack.isEmpty {
                            Text("All caught up!")
                                .fullWidth()
                        } else {
                            penPalList(data: data)
                        }
                        if widgetFamily == .systemLarge {
                            Spacer()
                        }
                    }
                    .padding()
                    
                }
                    
            } else {
                Text("No data")
            }
        }
        .fontDesign(.rounded)
        .onPreferenceChange(WidgetIconWidthPreferenceKey.self) { value in
            self.iconWidth = value
        }
    }
    
    struct WidgetIconWidthPreferenceKey: PreferenceKey {
        static let defaultValue: CGFloat = 20
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = max(value, nextValue())
        }
    }
    
}

struct PendulumWidget: Widget {
    let kind: String = "PendulumWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            PendulumWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Replies to write")
        .description("List people you need to reply to, and any letters you need to post.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct PendulumWidget_Previews: PreviewProvider {
    static var previews: some View {
        PendulumWidgetEntryView(entry: SimpleEntry(date: Date(), data: WidgetData(
            toSendCount: 0,
            toWriteBack: [
                WidgetDataPerson(id: UUID(), name: "Ellen Durack", lastEventDate: Date()),
                WidgetDataPerson(id: UUID(), name: "Kymbat Filin and their Exciting Trip To Germany", lastEventDate: Date()),
                WidgetDataPerson(id: UUID(), name: "Alex Faber the First", lastEventDate: Date()),
                WidgetDataPerson(id: UUID(), name: "Alex Faber the Second", lastEventDate: Date()),
                WidgetDataPerson(id: UUID(), name: "Alex Faber the Second", lastEventDate: Date()),
                WidgetDataPerson(id: UUID(), name: "Alex Faber the Fourteenth and his Lovely Wife", lastEventDate: Date()),
                WidgetDataPerson(id: UUID(), name: "Alex Faber the Second", lastEventDate: Date()),
                WidgetDataPerson(id: UUID(), name: "Alex Faber the Second", lastEventDate: Date())
            ]
        ), configuration: ConfigurationIntent()))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
