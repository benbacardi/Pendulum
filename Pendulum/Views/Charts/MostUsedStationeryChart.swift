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

    @State private var data: [ParameterCount] = []
    @ScaledMetric(relativeTo: .body) private var rowHeight: CGFloat = 50

    var body: some View {
        ScrollView {
            GroupBox {
                Chart(data) { data in
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
                .frame(height: Double(data.count) * rowHeight)
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
                self.data = data.filter { $0.count > 0 }.sorted()
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
