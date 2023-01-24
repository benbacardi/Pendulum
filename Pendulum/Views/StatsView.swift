//
//  StatsView.swift
//  Pendulum
//
//  Created by Ben Cardy on 18/01/2023.
//

import SwiftUI
import Charts

struct StatsView: View {
    
    @State private var iconWidth: CGFloat?
    
    @State private var mostUsedPen: ParameterCount? = nil // ParameterCount(name: "Lamy Safari Pink B", count: 3, type: .pen)
    @State private var mostUsedInk: ParameterCount? = nil // ParameterCount(name: "Lamy Amazonite", count: 3, type: .ink)
    @State private var mostUsedPaper: ParameterCount? = nil // ParameterCount(name: "Clairefontaine Triomphe A5 Plain", count: 8, type: .paper)
    
    @State private var averageTimeToReply: Double = 0
    @State private var numberReceived: Int = 0
    @State private var numberSent: Int = 0
    
    @State private var mostCommonRecipients: [PenPal] = []
    @State private var mostProlificPenPals: [PenPal] = []
    @State private var mostCommonRecipientCount: Int = 0
    @State private var mostProlificPenPalCount: Int = 0
    
    @State private var sentTypes: [LetterType: Int] = [:]
    @State private var receivedTypes: [LetterType: Int] = [:]
    
    @ViewBuilder
    func mostUsed(_ parameter: ParameterCount? = nil, placeholder: StationeryType? = nil) -> some View {
        GroupBox {
            HStack {
                Image(systemName: (parameter?.type ?? placeholder ?? .pen).icon)
                    .frame(width: iconWidth)
                    .background(GeometryReader { geo in
                        Color.clear.preference(key: Self.IconWidthPreferenceKey.self, value: max(geo.size.width, geo.size.height))
                    })
                if let parameter = parameter {
                    Text(parameter.name)
                        .fullWidth()
                    if parameter.count > 0 {
                        Text("\(parameter.count)")
                            .font(.headline)
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("Placeholder Pen").fullWidth().redacted(reason: .placeholder)
                }
            }
        }
        .foregroundColor(.primary)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    
                    GroupBox {
                        HStack {
                            VStack {
                                Text(UserDefaults.shared.trackPostingLetters ? "Sent" : "Written")
                                    .font(.headline)
                                .foregroundColor((UserDefaults.shared.trackPostingLetters ? EventType.sent : EventType.written).color)
                                
                                Text("\(numberSent)")
                                    .font(.system(size: 40, design: .rounded))
                                    .bold()
                                    .padding(.top, 1)
                            }
                            .fullWidth(alignment: .center)
                            Divider()
                            VStack {
                                Text("Received")
                                    .font(.headline)
                                .foregroundColor(EventType.received.color)
                                Text("\(numberReceived)")
                                    .font(.system(size: 40, design: .rounded))
                                    .bold()
                                    .padding(.top, 1)
                            }
                            .fullWidth(alignment: .center)
                        }
                    }
                    
                    GroupBox {
                        Text("Average time to respond to a letter")
                            .fullWidth(alignment: .center)
                            .font(.headline)
                        Text("\(averageTimeToReply.roundToDecimalPlaces(1)) day\(averageTimeToReply == 1 ? "s" : "")")
                            .fullWidth(alignment: .center)
                            .font(.system(size: 40, design: .rounded))
                            .bold()
                            .padding(.top, 1)
                    }
                    
                    GroupBox {
                        Text("Items sent by type")
                            .fullWidth()
                            .font(.headline)
                        Chart {
                            ForEach(LetterType.allCases) { type in
                                let sentCount = sentTypes[type] ?? 0
                                BarMark(
                                    x: .value("Type", type),
                                    y: .value("Count", sentCount)
                                )
                                .annotation(position: .top, alignment: .top) {
                                    if sentCount != 0 {
                                        Text("\(sentCount)")
                                            .font(.footnote)
                                            .bold()
                                            .foregroundColor(EventType.sent.color)
                                            .opacity(0.5)
                                    }
                                }
                                .foregroundStyle(by: .value("type", EventType.sent))
                                .position(by: .value("type", EventType.sent))
                                let receivedCount = receivedTypes[type] ?? 0
                                BarMark(
                                    x: .value("Type", type),
                                    y: .value("Count", receivedCount)
                                )
                                .annotation(position: .top, alignment: .top) {
                                    if receivedCount != 0 {
                                        Text("\(receivedCount)")
                                            .font(.footnote)
                                            .bold()
                                            .foregroundColor(EventType.received.color)
                                            .opacity(0.5)
                                    }
                                }
                                .foregroundStyle(by: .value("type", EventType.received))
                                .position(by: .value("type", EventType.received))
                            }
                        }
                        .chartForegroundStyleScale([
                            EventType.sent: EventType.sent.color,
                            EventType.received: EventType.received.color,
                        ])
                        .frame(height: 150)
                    }
                    
                    SentAndWrittenByDayOfWeekChart()
                    
                    GroupBox {
                        Text("Most used stationery")
                            .font(.headline)
                            .fullWidth()
                        if let pen = mostUsedPen {
                            NavigationLink(destination: MostUsedStationeryChart(stationeryType: .pen)) {
                                mostUsed(pen)
                            }
                        } else {
                            mostUsed(placeholder: .pen)
                        }
                        if let ink = mostUsedInk {
                            NavigationLink(destination: MostUsedStationeryChart(stationeryType: .ink)) {
                                mostUsed(ink)
                            }
                        } else {
                            mostUsed(placeholder: .ink)
                        }
                        if let paper = mostUsedPaper {
                            NavigationLink(destination: MostUsedStationeryChart(stationeryType: .paper)) {
                                mostUsed(paper)
                            }
                        } else {
                            mostUsed(placeholder: .paper)
                        }
                    }
                    
                    if !mostCommonRecipients.isEmpty {
                        GroupBox {
                            Text("Most common recipient")
                                .font(.headline)
                                .fullWidth()
                            ForEach(mostCommonRecipients) { penpal in
                                PenPalListItem(penpal: penpal, asListItem: false, subText: "You've sent them \(mostCommonRecipientCount) item\(mostCommonRecipientCount == 1 ? "s" : "")")
                            }
                        }
                    }
                    
                    if !mostProlificPenPals.isEmpty {
                        GroupBox {
                            Text("Most prolific Pen Pal")
                                .font(.headline)
                                .fullWidth()
                            ForEach(mostProlificPenPals) { penpal in
                                PenPalListItem(penpal: penpal, asListItem: false, subText: "They've sent you \(mostProlificPenPalCount) item\(mostProlificPenPalCount == 1 ? "s" : "")")
                            }
                        }
                    }
                    
                }
                .padding()
            }
            .onPreferenceChange(Self.IconWidthPreferenceKey.self) { value in
                self.iconWidth = value
            }
            .navigationTitle("Statistics")
            .task {
                
                // Calculate stationery stats
                
                let mostUsedPen = PenPal.fetchDistinctStationery(ofType: .pen).filter { $0.count != 0 }.first
                let mostUsedInk = PenPal.fetchDistinctStationery(ofType: .ink).filter { $0.count != 0 }.first
                let mostUsedPaper = PenPal.fetchDistinctStationery(ofType: .paper).filter { $0.count != 0 }.first
                
                DispatchQueue.main.async {
                    withAnimation {
                        self.mostUsedPen = mostUsedPen
                        self.mostUsedInk = mostUsedInk
                        self.mostUsedPaper = mostUsedPaper
                    }
                }
                
                // Calculate reply stats
                
                let averageTimeToReply = PenPal.averageTimeToRespond()
                
                DispatchQueue.main.async {
                    withAnimation {
                        self.averageTimeToReply = averageTimeToReply
                    }
                }
                
                // Calculate Sent/Received stats
                        
                let allSent: [Event]
                if UserDefaults.shared.trackPostingLetters {
                    allSent = Event.fetch(withStatus: [.sent])
                } else {
                    allSent = Event.fetch(withStatus: [.written])
                }
                let allReceived: [Event] = Event.fetch(withStatus: [.received])
                let numberReceived = allReceived.count
                let numberSent = allSent.count
                
                DispatchQueue.main.async {
                    withAnimation {
                        self.numberSent = numberSent
                        self.numberReceived = numberReceived
                    }
                }
                
                // Calculate most common recipients
                                
                let mostSent = allSent.reduce(into: [PenPal: Int]()) {
                    $0[$1.penpal] = ($0[$1.penpal] ?? 0) + 1
                }
                
                var mostCommonRecipients: [PenPal] = []
                var mostCommonRecipientCount: Int = 0
                if let highest = mostSent.values.max(), highest > 0 {
                    mostCommonRecipientCount = highest
                    mostCommonRecipients = mostSent.filter { $0.value == highest }.compactMap { $0.key }.sorted {
                        $0.wrappedName < $1.wrappedName
                    }
                }
                
                // Calculate most prolific pen pals
                
                let mostReceived = allReceived.reduce(into: [PenPal: Int]()) {
                    $0[$1.penpal] = ($0[$1.penpal] ?? 0) + 1
                }
                
                var mostProlificPenPals: [PenPal] = []
                var mostProlificPenPalCount: Int = 0
                if let highest = mostReceived.values.max(), highest > 0 {
                    mostProlificPenPalCount = highest
                    mostProlificPenPals = mostReceived.filter { $0.value == highest }.compactMap { $0.key }.sorted {
                        $0.wrappedName < $1.wrappedName
                    }
                }
                
                // Calculate letter type stats
                
                let sentTypes = allSent.reduce(into: [LetterType: Int]()) {
                    $0[$1.letterType] = ($0[$1.letterType] ?? 0) + 1
                }
                
                let receivedTypes = allReceived.reduce(into: [LetterType: Int]()) {
                    $0[$1.letterType] = ($0[$1.letterType] ?? 0) + 1
                }
                
                // Update UI
                
                DispatchQueue.main.async {
                    withAnimation {
                        self.mostCommonRecipients = mostCommonRecipients
                        self.mostProlificPenPals = mostProlificPenPals
                        self.mostCommonRecipientCount = mostCommonRecipientCount
                        self.mostProlificPenPalCount = mostProlificPenPalCount
                        self.sentTypes = sentTypes
                        self.receivedTypes = receivedTypes
                    }
                }
            }
        }
    }
}

private extension StatsView {
    struct IconWidthPreferenceKey: PreferenceKey {
        static let defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = max(value, nextValue())
        }
    }
}

struct StatsView_Previews: PreviewProvider {
    static var previews: some View {
        StatsView()
    }
}
