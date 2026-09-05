//
//  StationeryTypeSection.swift
//  Pendulum
//
//  Created by Ben Cardy on 10/11/2022.
//

import SwiftUI

/// One `pen`/`ink`/`paper` section of `EventPropertyDetailsSheet`'s list — the entries recorded for
/// that stationery type, plus an inline "Add…" row when adding is allowed.
struct StationeryTypeSection: View {

    @Environment(\.managedObjectContext) var moc

    let type: StationeryType
    @Binding var options: [ParameterCount]
    @Binding var newEntry: String
    var focused: FocusState<Bool>.Binding
    let allowAdding: Bool
    let outbound: Bool
    let onRename: (ParameterCount) -> Void

    var body: some View {
        Section(header: HStack {
            type.iconImage
            Text(type.namePlural)
        }) {
            if options.isEmpty && !(allowAdding && outbound) {
                Text("None recorded yet")
                    .foregroundStyle(.secondary)
            }
            ForEach(options, id: \.name) { option in
                StationeryRow(option: option, onRename: { onRename(option) }) {
                    Stationery.delete(option, in: moc)
                    withAnimation {
                        options.removeAll { $0 == option }
                    }
                }
            }
            if allowAdding && outbound {
                HStack {
                    TextField("Add…", text: $newEntry)
                        .focused(focused)
                    if focused.wrappedValue {
                        Button(action: {
                            let stationery = Stationery(context: moc)
                            stationery.id = UUID()
                            stationery.value = newEntry
                            stationery.type = type.recordType
                            withAnimation {
                                PersistenceController.shared.save(context: moc)
                                options.append(ParameterCount(name: stationery.wrappedValue, count: 0, type: type, customType: nil))
                                focused.wrappedValue = false
                                newEntry = ""
                            }
                        }) {
                            Text("Save")
                                .foregroundStyle(Color.accentColor)
                        }
                        .buttonStyle(.plain)
                        .disabled(newEntry.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || options.map { $0.name }.contains(newEntry.trimmingCharacters(in: .whitespacesAndNewlines)))
                    }
                }
            }
        }
    }
}
