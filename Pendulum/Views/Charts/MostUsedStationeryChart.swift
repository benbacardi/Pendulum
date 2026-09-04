//
//  MostUsedStationeryChart.swift
//  Pendulum
//
//  Created by Ben Cardy on 18/01/2023.
//

import SwiftUI
import Charts

struct MostUsedStationeryChart: View {
    
    let stationeryType: StationeryType?
    let customStationeryType: CustomStationeryType?
    let selectedYear: Int?

    @State private var data: [ParameterCount] = [
//        ParameterCount(name: "Lamy Safari Pink B", count: 3, type: .pen),
//        ParameterCount(name: "TWSBI Eco Clear M", count: 3, type: .pen),
//        ParameterCount(name: "Jinhao Shark", count: 2, type: .pen),
//        ParameterCount(name: "Lamy AL Star Azure B", count: 1, type: .pen),
//        ParameterCount(name: "Just Turnings Erriapus Kirinite Arctic Blue B", count: 0, type: .pen),
//        ParameterCount(name: "Kaweco Skyline Sport Fox B", count: 0, type: .pen),
//        ParameterCount(name: "Lamy Amazonite", count: 3, type: .ink),
//        ParameterCount(name: "Krishna Shamrock", count: 2, type: .ink),
//        ParameterCount(name: "Robert Oster Signature Hot Pink", count: 2, type: .ink),
//        ParameterCount(name: "Diamine Cosy Up", count: 1, type: "Ink"),
//        ParameterCount(name: "Diamine Jingle Berry", count: 1, type: "Ink"),
//        ParameterCount(name: "Diamine Yule Log", count: 1, type: "Ink"),
//        ParameterCount(name: "Clairefontaine Triomphe A5 Plain", count: 8, type: .paper),
//        ParameterCount(name: "Clairefontaine Triomphe A5 Lined", count: 2, type: .paper),
    ]
    
    var parsedData: [ParameterCount] {
        data.filter { $0.count > 0 }.sorted()
    }
    
    var body: some View {
        ScrollView {
            GroupBox {
                Chart(parsedData) { data in
                    BarMark(
                        x: .value("Count", data.count),
                        y: .value("Pen", data.name)
                    )
                    .annotation(position: .overlay, alignment: .trailing) {
                        Text("\(data.count)")
                            .font(.footnote)
                            .bold()
                            .foregroundStyle(.white)
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisValueLabel()
                    }
                }
                .chartXAxis(.hidden)
                .frame(height: CGFloat(parsedData.count * 50))
            }
            .task(id: selectedYear) {
                let stationeryType = self.stationeryType
                let customStationeryType = self.customStationeryType
                let selectedYear = self.selectedYear
                let data = await PersistenceController.shared.fetching { context -> [ParameterCount] in
                    if let stationeryType {
                        return PenPal.fetchDistinctStationery(ofType: stationeryType, year: selectedYear, from: context)
                    }
                    if let customStationeryType {
                        return PenPal.fetchDistinctCustomStationery(ofType: customStationeryType, year: selectedYear, from: context)
                    }
                    return []
                }
                self.data = data
            }
            .padding()
            .navigationTitle(stationeryType?.namePlural ?? customStationeryType?.type ?? "Stationery")
        }
    }
}

#Preview {
    NavigationStack {
        MostUsedStationeryChart(stationeryType: .pen, customStationeryType: nil, selectedYear: nil)
    }
}
