//
//  EventStationeryFieldsSection.swift
//  Pendulum
//
//  Created by Ben Cardy on 21/11/2022.
//

import SwiftUI

/// The pen/ink/paper fields, plus any custom stationery types — one section of `AddEventSheet`'s
/// form. Headed by a reminder of what was used last time, when replying to a written event.
struct EventStationeryFieldsSection: View {

    let priorWrittenEvent: Event?
    @Binding var pen: String
    @Binding var ink: String
    @Binding var paper: String
    let penSuggestions: [String]
    let inkSuggestions: [String]
    let paperSuggestions: [String]
    @Binding var iconWidth: CGFloat
    @Binding var customStationeryTypes: [CustomStationeryType]

    private var priorWrittenEventHeaderText: String {
        guard let priorWrittenEvent else { return "" }
        return Calendar.current.verboseNumberOfDaysBetween(priorWrittenEvent.wrappedDate, and: Date())
    }

    var body: some View {
        Section(header: Group {
            if let priorWrittenEvent {
                Text("You wrote the \(priorWrittenEvent.letterType.description) \(priorWrittenEventHeaderText).").textCase(nil)
            } else {
                EmptyView()
            }
        }) {
            StationeryTypeView(icon: StationeryType.pen.icon, title: priorWrittenEvent?.pen ?? "Pen", text: $pen, suggestions: penSuggestions, suggestionTitle: "Choose Pens", iconWidth: $iconWidth)
            StationeryTypeView(icon: StationeryType.ink.icon, title: priorWrittenEvent?.ink ?? "Ink", text: $ink, suggestions: inkSuggestions, suggestionTitle: "Choose Inks", iconWidth: $iconWidth)
            StationeryTypeView(icon: StationeryType.paper.icon, title: priorWrittenEvent?.paper ?? "Paper", text: $paper, suggestions: paperSuggestions, suggestionTitle: "Choose Paper", iconWidth: $iconWidth)

            ForEach($customStationeryTypes) { $customStationeryType in
                CustomStationeryTypeView(type: $customStationeryType, iconWidth: $iconWidth)
            }
        }
    }
}
