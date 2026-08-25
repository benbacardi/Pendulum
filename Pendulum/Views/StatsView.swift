//
//  StatsView.swift
//  Pendulum
//
//  Created by Ben Cardy on 18/01/2023.
//

import SwiftUI
import Charts

struct StatsView: View {
    
    @Environment(\.managedObjectContext) var moc

    @AppStorage(UserDefaults.Key.trackPostingLetters, store: UserDefaults.shared) private var trackPostingLetters: Bool = true

    @State private var iconWidth: CGFloat?
    @State private var inbound: Bool = false

    @State private var selectedYear: Int? = nil
    @State private var availableYears: [Int] = []
    
    @State private var mostUsedPen: ParameterCount? = nil
    @State private var mostUsedInk: ParameterCount? = nil
    @State private var mostUsedPaper: ParameterCount? = nil

    @State private var mostUsedCustom: [CustomStationeryType: ParameterCount?] = [:]

    @State private var averageTimeToReply: Double? = nil
    @State private var numberReceived: Int = 0
    @State private var numberSent: Int = 0
    
    @State private var mostCommonRecipients: [PenPal] = []
    @State private var mostProlificPenPals: [PenPal] = []
    @State private var mostCommonRecipientCount: Int = 0
    @State private var mostProlificPenPalCount: Int = 0
    
    @State private var events: [Event] = []
    
    @State private var sentTypes: [LetterType: Int] = [:]
    @State private var receivedTypes: [LetterType: Int] = [:]
    
    @ViewBuilder
    func yearPill(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: {
            withAnimation {
                action()
            }
        }) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color(uiColor: .secondarySystemBackground))
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }

    @ViewBuilder
    func mostUsed(_ parameter: ParameterCount? = nil, placeholder: StationeryType? = nil) -> some View {
        GroupBox {
            HStack {
                Image(systemName: parameter?.icon ?? placeholder?.icon ?? StationeryType.pen.icon)
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
        ScrollView {
            VStack(spacing: 20) {

                if availableYears.count > 1 {
                    ScrollViewReader { yearScrollProxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                yearPill(title: "All Time", isSelected: selectedYear == nil) {
                                    self.selectedYear = nil
                                }
                                .id(-1)
                                ForEach(availableYears, id: \.self) { year in
                                    yearPill(title: String(year), isSelected: selectedYear == year) {
                                        self.selectedYear = year
                                    }
                                    .id(year)
                                }
                            }
                            .padding(.horizontal)
                        }
                        .onChange(of: selectedYear) { newValue in
                            withAnimation {
                                yearScrollProxy.scrollTo(newValue ?? -1, anchor: .center)
                            }
                        }
                    }
                }

                VStack(spacing: 20) {

                GroupBox {
                    HStack {
                        VStack {
                            Text(trackPostingLetters ? "Sent" : "Written")
                                .font(.headline)
                                .foregroundColor((trackPostingLetters ? EventType.sent : EventType.written).color)
                            
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
                    if let averageTimeToReply {
                        Text("\(averageTimeToReply.roundToDecimalPlaces(1)) day\(averageTimeToReply == 1 ? "" : "s")")
                            .fullWidth(alignment: .center)
                            .font(.system(size: 40, design: .rounded))
                            .bold()
                            .padding(.top, 1)
                    } else {
                        Text("–")
                            .fullWidth(alignment: .center)
                            .font(.system(size: 40, design: .rounded))
                            .bold()
                            .padding(.top, 1)
                    }
                }
                
                
                GroupBox {
                    
                    VStack(spacing: 15) {
                        
                        Picker("Inbound", selection: $inbound.animation()) {
                            Text("Written & Sent").tag(false)
                            Text("Received").tag(true)
                        }
                        .pickerStyle(.segmented)
                        SentByTypeChart(showInbound: $inbound, sentTypes: $sentTypes, receivedTypes: $receivedTypes)
                        SentAndWrittenByDayOfWeekChart(events: $events, showInbound: $inbound)
                        SentAndWrittenByMonthChart(events: $events, showInbound: $inbound)
                    }
                    
                }
                
                GroupBox {
                    Text("Most used stationery")
                        .font(.headline)
                        .fullWidth()
                    if let pen = mostUsedPen {
                        NavigationLink(destination: MostUsedStationeryChart(stationeryType: .pen, customStationeryType: nil, selectedYear: selectedYear)) {
                            mostUsed(pen)
                        }
                    } else {
                        mostUsed(placeholder: .pen)
                    }
                    if let ink = mostUsedInk {
                        NavigationLink(destination: MostUsedStationeryChart(stationeryType: .ink, customStationeryType: nil, selectedYear: selectedYear)) {
                            mostUsed(ink)
                        }
                    } else {
                        mostUsed(placeholder: .ink)
                    }
                    if let paper = mostUsedPaper {
                        NavigationLink(destination: MostUsedStationeryChart(stationeryType: .paper, customStationeryType: nil, selectedYear: selectedYear)) {
                            mostUsed(paper)
                        }
                    } else {
                        mostUsed(placeholder: .paper)
                    }

                    ForEach(Array(mostUsedCustom.keys).sorted(using: KeyPathComparator(\.type)), id: \.self) { stationeryType in
                        if let count = mostUsedCustom[stationeryType] {
                            NavigationLink(destination: MostUsedStationeryChart(stationeryType: nil, customStationeryType: stationeryType, selectedYear: selectedYear)) {
                                mostUsed(count)
                            }
                        }
                    }
                }
                
                if !mostCommonRecipients.isEmpty {
                    GroupBox {
                        Text("Most common recipient")
                            .font(.headline)
                            .fullWidth()
                        ForEach(mostCommonRecipients) { penpal in
                            PenPalListItem(penpal: penpal, asListItem: false, subText: "You've sent them \(mostCommonRecipientCount) item\(mostCommonRecipientCount == 1 ? "" : "s")")
                        }
                    }
                }
                
                if !mostProlificPenPals.isEmpty {
                    GroupBox {
                        Text("Most prolific Pen Pal")
                            .font(.headline)
                            .fullWidth()
                        ForEach(mostProlificPenPals) { penpal in
                            PenPalListItem(penpal: penpal, asListItem: false, subText: "They've sent you \(mostProlificPenPalCount) item\(mostProlificPenPalCount == 1 ? "" : "s")")
                        }
                    }
                }

                }
                .padding(.horizontal)

            }
            .padding(.vertical)
        }
        .onPreferenceChange(Self.IconWidthPreferenceKey.self) { value in
            self.iconWidth = value
        }
        .navigationTitle("Statistics")
        .task {
            if let earliestDate = Event.fetchEarliestDate(from: moc) {
                let earliestYear = Calendar.current.component(.year, from: earliestDate)
                let currentYear = Calendar.current.component(.year, from: Date())
                let years = Array((min(earliestYear, currentYear)...currentYear).reversed())
                DispatchQueue.main.async {
                    self.availableYears = years
                }
            }
        }
        .task(id: selectedYear) {
            let interestingEvents = Event.fetch(withStatus: [.written, .sent, .received], year: selectedYear, from: moc)
            DispatchQueue.main.async {
                withAnimation {
                    self.events = interestingEvents
                }
            }
        }
        .task(id: statsQuery) {

            // Calculate stationery stats

            let mostUsedPen = PenPal.fetchDistinctStationery(ofType: .pen, year: selectedYear, from: moc).filter { $0.count != 0 }.first
            let mostUsedInk = PenPal.fetchDistinctStationery(ofType: .ink, year: selectedYear, from: moc).filter { $0.count != 0 }.first
            let mostUsedPaper = PenPal.fetchDistinctStationery(ofType: .paper, year: selectedYear, from: moc).filter { $0.count != 0 }.first

            let mostUsedCustom = PenPal.fetchDistinctCustomStationery(year: selectedYear, from: moc).filter { !$0.value.isEmpty }.mapValues { $0.first }

            DispatchQueue.main.async {
                withAnimation {
                    self.mostUsedPen = mostUsedPen
                    self.mostUsedInk = mostUsedInk
                    self.mostUsedPaper = mostUsedPaper
                    self.mostUsedCustom = mostUsedCustom
                }
            }

            // Calculate reply stats

            let averageTimeToReply = PenPal.averageTimeToRespond(year: selectedYear, from: moc)

            DispatchQueue.main.async {
                withAnimation {
                    self.averageTimeToReply = averageTimeToReply
                }
            }

            // Calculate Sent/Received stats

            let allSent: [Event]
            if trackPostingLetters {
                allSent = Event.fetch(withStatus: [.sent], year: selectedYear, from: moc)
            } else {
                allSent = Event.fetch(withStatus: [.written], year: selectedYear, from: moc)
            }
            let allReceived: [Event] = Event.fetch(withStatus: [.received], year: selectedYear, from: moc)
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
                mostCommonRecipients = mostSent.filter { $0.value == highest }.compactMap { $0.key }.sorted(using: KeyPathComparator(\.wrappedName))
            }
            
            // Calculate most prolific pen pals
            
            let mostReceived = allReceived.reduce(into: [PenPal: Int]()) {
                $0[$1.penpal] = ($0[$1.penpal] ?? 0) + 1
            }
            
            var mostProlificPenPals: [PenPal] = []
            var mostProlificPenPalCount: Int = 0
            if let highest = mostReceived.values.max(), highest > 0 {
                mostProlificPenPalCount = highest
                mostProlificPenPals = mostReceived.filter { $0.value == highest }.compactMap { $0.key }.sorted(using: KeyPathComparator(\.wrappedName))
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

private extension StatsView {
    /// The inputs the sent/received counts depend on. Both have to be watched, or
    /// toggling "Track posting letters" relabels the figures without recounting them.
    struct StatsQuery: Equatable {
        let year: Int?
        let trackPostingLetters: Bool
    }

    var statsQuery: StatsQuery {
        StatsQuery(year: selectedYear, trackPostingLetters: trackPostingLetters)
    }

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
