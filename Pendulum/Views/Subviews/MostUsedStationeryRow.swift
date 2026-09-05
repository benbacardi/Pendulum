//
//  MostUsedStationeryRow.swift
//  Pendulum
//
//  Created by Ben Cardy on 18/01/2023.
//

import SwiftUI

struct MostUsedStationeryRow: View {

    let parameter: ParameterCount?
    let placeholder: StationeryType?
    let iconWidth: CGFloat?

    init(_ parameter: ParameterCount? = nil, placeholder: StationeryType? = nil, iconWidth: CGFloat?) {
        self.parameter = parameter
        self.placeholder = placeholder
        self.iconWidth = iconWidth
    }

    var body: some View {
        GroupBox {
            HStack {
                StationeryType.image(forIcon: parameter?.icon ?? placeholder?.icon ?? StationeryType.pen.icon)
                    .frame(width: iconWidth)
                    .background(GeometryReader { geo in
                        Color.clear.preference(key: IconWidthPreferenceKey.self, value: max(geo.size.width, geo.size.height))
                    })
                if let parameter = parameter {
                    Text(parameter.name)
                        .fullWidth()
                    if parameter.count > 0 {
                        Text("\(parameter.count)")
                            .font(.headline)
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("Placeholder Pen").fullWidth().redacted(reason: .placeholder)
                }
            }
        }
        .foregroundStyle(.primary)
    }
}

extension MostUsedStationeryRow {
    struct IconWidthPreferenceKey: PreferenceKey {
        static let defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = max(value, nextValue())
        }
    }
}

#Preview {
    MostUsedStationeryRow(placeholder: .pen, iconWidth: 20)
}
