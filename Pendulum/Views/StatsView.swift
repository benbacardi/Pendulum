//
//  StatsView.swift
//  Pendulum
//
//  Created by Ben Cardy on 18/01/2023.
//

import SwiftUI
import Charts
import CoreData

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
    /// Optional so the first load shows a placeholder rather than a confident zero — the fetch
    /// is asynchronous, and zero is a real answer we don't have yet. A reload keeps the previous
    /// value on screen, because these are only assigned once the new figures arrive.
    @State private var numberReceived: Int? = nil
    @State private var numberSent: Int? = nil
    
    @State private var mostCommonRecipients: [PenPal] = []
    @State private var mostProlificPenPals: [PenPal] = []
    @State private var mostCommonRecipientCount: Int = 0
    @State private var mostProlificPenPalCount: Int = 0
    
    @State private var events: [Event] = []
    
    @State private var sentTypes: [LetterType: Int] = [:]
    @State private var receivedTypes: [LetterType: Int] = [:]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                if availableYears.count > 1 {
                    ScrollViewReader { yearScrollProxy in
                        ScrollView(.horizontal) {
                            HStack(spacing: 8) {
                                YearPill(title: "All Time", isSelected: selectedYear == nil) {
                                    self.selectedYear = nil
                                }
                                .id(-1)
                                ForEach(availableYears, id: \.self) { year in
                                    YearPill(title: String(year), isSelected: selectedYear == year) {
                                        self.selectedYear = year
                                    }
                                    .id(year)
                                }
                            }
                            .padding(.horizontal)
                        }
                        .scrollIndicators(.hidden)
                        .onChange(of: selectedYear) { _, newValue in
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
                                .foregroundStyle((trackPostingLetters ? EventType.sent : EventType.written).color)
                            
                            Text(numberSent.map(String.init) ?? "–")
                                .font(.system(.largeTitle, design: .rounded))
                                .bold()
                                .padding(.top, 1)
                        }
                        .fullWidth(alignment: .center)
                        Divider()
                        VStack {
                            Text("Received")
                                .font(.headline)
                                .foregroundStyle(EventType.received.color)
                            Text(numberReceived.map(String.init) ?? "–")
                                .font(.system(.largeTitle, design: .rounded))
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
                        Text("^[\(averageTimeToReply, specifier: averageTimeToReply.rounded() == averageTimeToReply ? "%.0f" : "%.1f") day](inflect: true)")
                            .fullWidth(alignment: .center)
                            .font(.system(.largeTitle, design: .rounded))
                            .bold()
                            .padding(.top, 1)
                    } else {
                        Text("–")
                            .fullWidth(alignment: .center)
                            .font(.system(.largeTitle, design: .rounded))
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
                            MostUsedStationeryRow(pen, iconWidth: iconWidth)
                        }
                    } else {
                        MostUsedStationeryRow(placeholder: .pen, iconWidth: iconWidth)
                    }
                    if let ink = mostUsedInk {
                        NavigationLink(destination: MostUsedStationeryChart(stationeryType: .ink, customStationeryType: nil, selectedYear: selectedYear)) {
                            MostUsedStationeryRow(ink, iconWidth: iconWidth)
                        }
                    } else {
                        MostUsedStationeryRow(placeholder: .ink, iconWidth: iconWidth)
                    }
                    if let paper = mostUsedPaper {
                        NavigationLink(destination: MostUsedStationeryChart(stationeryType: .paper, customStationeryType: nil, selectedYear: selectedYear)) {
                            MostUsedStationeryRow(paper, iconWidth: iconWidth)
                        }
                    } else {
                        MostUsedStationeryRow(placeholder: .paper, iconWidth: iconWidth)
                    }

                    ForEach(Array(mostUsedCustom.keys).sorted(using: KeyPathComparator(\.type)), id: \.self) { stationeryType in
                        if let count = mostUsedCustom[stationeryType] {
                            NavigationLink(destination: MostUsedStationeryChart(stationeryType: nil, customStationeryType: stationeryType, selectedYear: selectedYear)) {
                                MostUsedStationeryRow(count, iconWidth: iconWidth)
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
        .onPreferenceChange(MostUsedStationeryRow.IconWidthPreferenceKey.self) { value in
            self.iconWidth = value
        }
        .navigationTitle("Statistics")
        .task {
            let years = await Self.fetchAvailableYears()
            self.availableYears = years
        }
        .task(id: selectedYear) {
            let eventIDs = await Self.fetchInterestingEventIDs(year: selectedYear)
            withAnimation {
                self.events = self.objects(for: eventIDs)
            }
        }
        .task(id: statsQuery) {
            let stats = await Self.fetchStats(for: statsQuery)
            withAnimation {
                self.mostUsedPen = stats.mostUsedPen
                self.mostUsedInk = stats.mostUsedInk
                self.mostUsedPaper = stats.mostUsedPaper
                self.mostUsedCustom = stats.mostUsedCustom
                self.averageTimeToReply = stats.averageTimeToReply
                self.numberSent = stats.numberSent
                self.numberReceived = stats.numberReceived
                self.mostCommonRecipients = self.objects(for: stats.mostCommonRecipientIDs)
                self.mostProlificPenPals = self.objects(for: stats.mostProlificPenPalIDs)
                self.mostCommonRecipientCount = stats.mostCommonRecipientCount
                self.mostProlificPenPalCount = stats.mostProlificPenPalCount
                self.sentTypes = stats.sentTypes
                self.receivedTypes = stats.receivedTypes
            }
        }
    }
}

private extension StatsView {
    
    /// Everything the stats screen shows, gathered in one pass away from the main actor.
    ///
    /// Pen Pals and Events come back as object IDs rather than managed objects: those belong to
    /// the context that fetched them, so the view re-reads them on its own context.
    struct Stats {
        var mostUsedPen: ParameterCount? = nil
        var mostUsedInk: ParameterCount? = nil
        var mostUsedPaper: ParameterCount? = nil
        var mostUsedCustom: [CustomStationeryType: ParameterCount?] = [:]
        var averageTimeToReply: Double? = nil
        var numberSent: Int = 0
        var numberReceived: Int = 0
        var mostCommonRecipientIDs: [NSManagedObjectID] = []
        var mostProlificPenPalIDs: [NSManagedObjectID] = []
        var mostCommonRecipientCount: Int = 0
        var mostProlificPenPalCount: Int = 0
        var sentTypes: [LetterType: Int] = [:]
        var receivedTypes: [LetterType: Int] = [:]
    }
    
    /// Re-reads objects the background context found on the view's own context.
    func objects<T: NSManagedObject>(for ids: [NSManagedObjectID]) -> [T] {
        ids.compactMap { try? moc.existingObject(with: $0) as? T }
    }
    
    static func fetchAvailableYears() async -> [Int] {
        await PersistenceController.shared.fetching { context in
            guard let earliestDate = Event.fetchEarliestDate(from: context) else { return [] }
            let earliestYear = Calendar.current.component(.year, from: earliestDate)
            let currentYear = Calendar.current.component(.year, from: Date())
            return Array((min(earliestYear, currentYear)...currentYear).reversed())
        }
    }
    
    static func fetchInterestingEventIDs(year: Int?) async -> [NSManagedObjectID] {
        await PersistenceController.shared.fetching { context in
            Event.fetch(withStatus: [.written, .sent, .received], year: year, from: context).map { $0.objectID }
        }
    }
    
    static func fetchStats(for query: StatsQuery) async -> Stats {
        await PersistenceController.shared.fetching { context in
            let year = query.year
            var stats = Stats()
            
            // Stationery stats
            
            stats.mostUsedPen = PenPal.fetchDistinctStationery(ofType: .pen, year: year, from: context).filter { $0.count != 0 }.first
            stats.mostUsedInk = PenPal.fetchDistinctStationery(ofType: .ink, year: year, from: context).filter { $0.count != 0 }.first
            stats.mostUsedPaper = PenPal.fetchDistinctStationery(ofType: .paper, year: year, from: context).filter { $0.count != 0 }.first
            stats.mostUsedCustom = PenPal.fetchDistinctCustomStationery(year: year, from: context).filter { !$0.value.isEmpty }.mapValues { $0.first }
            
            // Reply stats
            
            stats.averageTimeToReply = PenPal.averageTimeToRespond(year: year, from: context)
            
            // Sent/received stats
            
            let allSent = Event.fetch(withStatus: query.trackPostingLetters ? [.sent] : [.written], year: year, from: context)
            let allReceived = Event.fetch(withStatus: [.received], year: year, from: context)
            stats.numberSent = allSent.count
            stats.numberReceived = allReceived.count
            
            // Most common recipients
            
            let mostSent = allSent.reduce(into: [PenPal: Int]()) {
                $0[$1.penpal] = ($0[$1.penpal] ?? 0) + 1
            }
            if let highest = mostSent.values.max(), highest > 0 {
                stats.mostCommonRecipientCount = highest
                stats.mostCommonRecipientIDs = mostSent.filter { $0.value == highest }.compactMap { $0.key }.sorted(using: KeyPathComparator(\.wrappedName)).map { $0.objectID }
            }
            
            // Most prolific Pen Pals
            
            let mostReceived = allReceived.reduce(into: [PenPal: Int]()) {
                $0[$1.penpal] = ($0[$1.penpal] ?? 0) + 1
            }
            if let highest = mostReceived.values.max(), highest > 0 {
                stats.mostProlificPenPalCount = highest
                stats.mostProlificPenPalIDs = mostReceived.filter { $0.value == highest }.compactMap { $0.key }.sorted(using: KeyPathComparator(\.wrappedName)).map { $0.objectID }
            }
            
            // Letter type stats
            
            stats.sentTypes = allSent.reduce(into: [LetterType: Int]()) {
                $0[$1.letterType] = ($0[$1.letterType] ?? 0) + 1
            }
            stats.receivedTypes = allReceived.reduce(into: [LetterType: Int]()) {
                $0[$1.letterType] = ($0[$1.letterType] ?? 0) + 1
            }
            
            return stats
        }
    }
    
    /// The inputs the sent/received counts depend on. Both have to be watched, or
    /// toggling "Track posting letters" relabels the figures without recounting them.
    struct StatsQuery: Equatable {
        let year: Int?
        let trackPostingLetters: Bool
    }

    var statsQuery: StatsQuery {
        StatsQuery(year: selectedYear, trackPostingLetters: trackPostingLetters)
    }
}

#Preview {
    StatsView()
}
