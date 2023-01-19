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
    
    @State private var averageTimeToReply: Double = 10.285714
    
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
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    
                    GroupBox {
                        Text("Most used stationery")
                            .font(.headline)
                            .fullWidth()
                        if let pen = mostUsedPen {
                            mostUsed(pen)
                        } else {
                            mostUsed(placeholder: .pen)
                        }
                        if let ink = mostUsedInk {
                            mostUsed(ink)
                        } else {
                            mostUsed(placeholder: .ink)
                        }
                        if let paper = mostUsedPaper {
                            mostUsed(paper)
                        } else {
                            mostUsed(placeholder: .paper)
                        }
                    }
                    
                    GroupBox {
                        Text("Average time to respond to a letter")
                            .fullWidth()
                            .font(.headline)
                        Text("\(PenPal.averageTimeToRespond().roundToDecimalPlaces(1)) days")
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
