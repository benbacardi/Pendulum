//
//  SentAndWrittenByDayOfWeekChart.swift
//  Pendulum
//
//  Created by Ben Cardy on 18/01/2023.
//

import SwiftUI
import Charts

struct StatusCountByDay: Identifiable {
    let status: EventType
    let day: Weekday
    let count: Int
    var id: String { "\(day)-\(status.rawValue)" }
}

let SENT_AND_WRITTEN_BY_DAY_OF_WEEK_DATA = [
    StatusCountByDay(status: .sent, day: .sun, count: 2),
    StatusCountByDay(status: .sent, day: .mon, count: 0),
    StatusCountByDay(status: .sent, day: .tue, count: 1),
    StatusCountByDay(status: .sent, day: .wed, count: 5),
    StatusCountByDay(status: .sent, day: .thu, count: 12),
    StatusCountByDay(status: .sent, day: .fri, count: 5),
    StatusCountByDay(status: .sent, day: .sat, count: 1),
    StatusCountByDay(status: .written, day: .mon, count: 2),
    StatusCountByDay(status: .written, day: .tue, count: 2),
    StatusCountByDay(status: .written, day: .wed, count: 1),
    StatusCountByDay(status: .written, day: .thu, count: 2),
    StatusCountByDay(status: .written, day: .fri, count: 1),
    StatusCountByDay(status: .written, day: .sat, count: 10),
    StatusCountByDay(status: .written, day: .sun, count: 3)
]

struct SentAndWrittenByDayOfWeekChart: View {
    
    @State private var data: [StatusCountByDay] = [
        StatusCountByDay(status: .sent, day: .sun, count: 0),
        StatusCountByDay(status: .sent, day: .mon, count: 0),
        StatusCountByDay(status: .sent, day: .tue, count: 0),
        StatusCountByDay(status: .sent, day: .wed, count: 0),
        StatusCountByDay(status: .sent, day: .thu, count: 0),
        StatusCountByDay(status: .sent, day: .fri, count: 0),
        StatusCountByDay(status: .sent, day: .sat, count: 0),
        StatusCountByDay(status: .written, day: .mon, count: 0),
        StatusCountByDay(status: .written, day: .tue, count: 0),
        StatusCountByDay(status: .written, day: .wed, count: 0),
        StatusCountByDay(status: .written, day: .thu, count: 0),
        StatusCountByDay(status: .written, day: .fri, count: 0),
        StatusCountByDay(status: .written, day: .sat, count: 0),
        StatusCountByDay(status: .written, day: .sun, count: 0)
    ]
    
    var body: some View {
        GroupBox {
            Text("Items written and sent per day of the week")
                .fullWidth()
                .font(.headline)
            Chart(data) { data in
                BarMark(
                    x: .value("Day", data.day.shortName),
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
            ])
            .frame(height: 200)
        }
        .task {
            
            var days: [Weekday: [Event]] = [:]
            
            for event in Event.fetch(withStatus: [.written, .sent]) {
                if !days.keys.contains(event.wrappedDate.weekday) {
                    days[event.wrappedDate.weekday] = []
                }
                days[event.wrappedDate.weekday]?.append(event)
            }
            
            var results: [StatusCountByDay] = []
            for eventType in [EventType.written, EventType.sent] {
                for day in Weekday.orderedCases {
                    let count = (days[day] ?? []).filter { $0.type == eventType }.count
                    results.append(StatusCountByDay(status: eventType, day: day, count: count))
                }
            }
            
            DispatchQueue.main.async {
                withAnimation {
                    self.data = results
                }
            }
            
        }
    }
}

struct SentAndWrittenByDayOfWeekChart_Previews: PreviewProvider {
    static var previews: some View {
        SentAndWrittenByDayOfWeekChart()
            .padding()
    }
}
