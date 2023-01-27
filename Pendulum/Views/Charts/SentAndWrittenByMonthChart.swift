//
//  SentAndWrittenByMonthChart.swift
//  Pendulum
//
//  Created by Ben Cardy on 18/01/2023.
//

import SwiftUI
import Charts

struct StatusCountByMonth: Identifiable {
    let status: EventType
    let month: Month
    let count: Int
    var id: String { "\(month.rawValue)-\(status.rawValue)" }
}

let EMPTY_STATUS_COUNTS_BY_MONTH: [StatusCountByMonth] = Month.allCases.map { StatusCountByMonth(status: .written, month: $0, count: 0) }

struct SentAndWrittenByMonthChart: View {
    
    @Binding var events: [Event]
    @Binding var showInbound: Bool
    
    @State private var outboundData: [StatusCountByMonth] = EMPTY_STATUS_COUNTS_BY_MONTH
    @State private var inboundData: [StatusCountByMonth] = EMPTY_STATUS_COUNTS_BY_MONTH
    
    var chartData: [StatusCountByMonth] {
        showInbound ? inboundData : outboundData
    }
    
    var body: some View {
        GroupBox {
            Text("By month")
                .fullWidth()
                .font(.headline)
            Chart(chartData) { data in
                BarMark(
                    x: .value("Day", data.month),
                    y: .value("Count", data.count)
                )
                .annotation(position: .top, alignment: .top) {
                    if data.count != 0 {
                        Text("\(data.count)")
                            .font(.footnote)
                            .bold()
                            .foregroundColor(data.status.color)
                            .opacity(0.5)
                    }
                }
                .foregroundStyle(by: .value("Event", data.status))
                .position(by: .value("event", data.status))
            }
            .chartForegroundStyleScale([
                EventType.sent: EventType.sent.color,
                EventType.written: EventType.written.color,
                EventType.received: EventType.received.color,
            ])
            .frame(height: 150)
        }
        .onChange(of: events) { _ in
            var months: [Month: [Event]] = [:]
            for event in events {
                if !months.keys.contains(event.wrappedDate.month) {
                    months[event.wrappedDate.month] = []
                }
                months[event.wrappedDate.month]?.append(event)
            }
            var inboundResults: [StatusCountByMonth] = []
            var outboundResults: [StatusCountByMonth] = []
            for eventType in [EventType.written, EventType.sent, EventType.received] {
                for month in Month.allCases {
                    let result = StatusCountByMonth(status: eventType, month: month, count: (months[month] ?? []).filter { $0.type == eventType }.count)
                    if eventType == .received {
                        inboundResults.append(result)
                    } else {
                        outboundResults.append(result)
                    }
                }
            }
            withAnimation {
                self.inboundData = inboundResults
                self.outboundData = outboundResults
            }
        }
    }
}

struct SentAndWrittenByMonthChart_Previews: PreviewProvider {
    static var previews: some View {
        SentAndWrittenByMonthChart(events: .constant([]), showInbound: .constant(false))
            .padding()
    }
}
