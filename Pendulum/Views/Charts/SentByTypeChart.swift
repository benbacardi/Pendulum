//
//  SentByTypeChart.swift
//  Pendulum
//
//  Created by Ben Cardy on 24/01/2023.
//

import SwiftUI
import Charts

struct SentByTypeChart: View {
    
    @Binding var sentTypes: [LetterType: Int]
    @Binding var receivedTypes: [LetterType: Int]
    
    func barMark(for type: LetterType, count: Int, ofType eventType: EventType) -> some ChartContent {
        BarMark(
            x: .value("Type", type),
            y: .value("Count", count)
        )
        .annotation(position: .top, alignment: .top) {
            if count != 0 {
                Text("\(count)")
                    .font(.footnote)
                    .bold()
                    .foregroundColor(eventType.color)
                    .opacity(0.5)
            }
        }
        .foregroundStyle(by: .value("type", eventType))
        .position(by: .value("type", eventType))
    }
    
    var body: some View {
        GroupBox {
            Text("Items sent by type")
                .fullWidth()
                .font(.headline)
            Chart {
                ForEach(LetterType.allCases) { type in
                    barMark(for: type, count: sentTypes[type] ?? 0, ofType: .sent)
                    barMark(for: type, count: receivedTypes[type] ?? 0, ofType: .received)
                }
            }
            .chartForegroundStyleScale([
                EventType.sent: EventType.sent.color,
                EventType.received: EventType.received.color,
            ])
            .frame(height: 150)
        }
    }
}

struct SentByTypeChart_Previews: PreviewProvider {
    static var previews: some View {
        SentByTypeChart(sentTypes: .constant([.postcard: 2]), receivedTypes: .constant([.postcard: 3, .package: 5]))
    }
}
