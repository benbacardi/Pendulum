//
//  CustomStationeryTypeView.swift
//  Pendulum
//
//  Created by Ben Cardy on 21/11/2022.
//

import SwiftUI

struct CustomStationeryTypeView: View {
    @Environment(\.managedObjectContext) var moc

    @Binding var type: CustomStationeryType
    @Binding var iconWidth: CGFloat

    @State private var suggestions: [String] = []

    var body: some View {
        StationeryTypeView(icon: type.icon, title: type.type, text: $type.value, suggestions: suggestions, suggestionTitle: "Choose \(type.type)", iconWidth: $iconWidth)
            .task {
                let type = type.type
                suggestions = await PersistenceController.shared.fetching { context in
                    CustomStationery.fetchDistinctValues(ofType: type, from: context)
                }
            }
    }
}
