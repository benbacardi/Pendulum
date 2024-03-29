//
//  MostUsedStationeryChart.swift
//  Pendulum
//
//  Created by Ben Cardy on 18/01/2023.
//

import SwiftUI
import Charts

struct MostUsedStationeryChart: View {
    
    @Environment(\.managedObjectContext) var moc
    
    let stationeryType: StationeryType
    
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
                            .foregroundColor(.white)
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
            .task {
                let data = PenPal.fetchDistinctStationery(ofType: self.stationeryType, from: moc)
                DispatchQueue.main.async {
                    self.data = data
                }
            }
            .padding()
            .navigationTitle(stationeryType.namePlural)
        }
    }
}

struct MostUsedPenChart_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MostUsedStationeryChart(stationeryType: .pen)
        }
    }
}
