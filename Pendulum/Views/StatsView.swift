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
                                HStack {
                                    Image(systemName: (UserDefaults.shared.trackPostingLetters ? EventType.sent : EventType.written).icon)
                                    Text(UserDefaults.shared.trackPostingLetters ? "Sent" : "Written")
                                        .font(.headline)
                                }
                                .foregroundColor((UserDefaults.shared.trackPostingLetters ? EventType.sent : EventType.written).color)
                                
                                Text("\(numberSent)")
                                    .font(.system(size: 40, design: .rounded))
                            }
                            .fullWidth(alignment: .center)
                            Divider()
                            VStack {
                                HStack {
                                    Image(systemName: EventType.received.icon)
                                    Text("Received")
                                        .font(.headline)
                                }
                                .foregroundColor(EventType.received.color)
                                Text("\(numberReceived)")
                                    .font(.system(size: 40, design: .rounded))
                            }
                            .fullWidth(alignment: .center)
                        }
                    }
                    
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
                    
                    GroupBox {
                        Text("Average time to respond to a letter")
                            .fullWidth()
                            .font(.headline)
                        Text("\(averageTimeToReply.roundToDecimalPlaces(1)) days")
                            .fullWidth()
                            .font(.system(size: 60, design: .rounded))
                    }
                    
                    SentAndWrittenByDayOfWeekChart()
                    
                }
                .padding()
            }
            .onPreferenceChange(Self.IconWidthPreferenceKey.self) { value in
                self.iconWidth = value
            }
            .navigationTitle("Statistics")
            .task {
                DispatchQueue.main.async {
                    withAnimation {
                        self.mostUsedPen = PenPal.fetchDistinctStationery(ofType: .pen).filter { $0.count != 0 }.first
                        self.mostUsedInk = PenPal.fetchDistinctStationery(ofType: .ink).filter { $0.count != 0 }.first
                        self.mostUsedPaper = PenPal.fetchDistinctStationery(ofType: .paper).filter { $0.count != 0 }.first
                        self.averageTimeToReply = PenPal.averageTimeToRespond()
                        if UserDefaults.shared.trackPostingLetters {
                            self.numberSent = Event.fetch(withStatus: [.sent]).count
                        } else {
                            self.numberSent = Event.fetch(withStatus: [.written]).count
                        }
                        self.numberReceived = Event.fetch(withStatus: [.received]).count
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
