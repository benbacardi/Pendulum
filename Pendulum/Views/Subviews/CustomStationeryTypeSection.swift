//
//  CustomStationeryTypeSection.swift
//  Pendulum
//
//  Created by Ben Cardy on 10/11/2022.
//

import SwiftUI

/// One user-defined stationery category's section of `EventPropertyDetailsSheet`'s list — same shape
/// as `StationeryTypeSection`, but keyed by a `CustomStationeryType` rather than the built-in
/// `StationeryType` enum, and with an Edit/Delete menu on the category itself.
struct CustomStationeryTypeSection: View {

    @Environment(\.managedObjectContext) var moc

    let key: CustomStationeryType
    let options: [ParameterCount]
    @Binding var newEntry: String
    var focused: FocusState<String?>.Binding
    let allowAdding: Bool
    let outbound: Bool
    let onRename: (ParameterCount) -> Void
    let onDelete: (ParameterCount) -> Void
    let onEditCategory: () -> Void
    let onDeleteCategory: () -> Void
    let onEntryAdded: () -> Void

    var body: some View {
        Section(header: HStack {
            Image(systemName: key.icon)
            Text(key.type)
            Spacer()
            Menu {
                Button(action: onEditCategory) {
                    Label("Edit", systemImage: "pencil")
                }
                Button(role: .destructive, action: onDeleteCategory) {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Label("More actions", systemImage: "ellipsis")
                    .labelStyle(.iconOnly)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }) {
            if options.isEmpty && !(allowAdding && outbound) {
                Text("None recorded yet")
                    .foregroundStyle(.secondary)
            }
            ForEach(options, id: \.name) { option in
                HStack {
                    Text(option.name)
                        .fullWidth()
                    if option.count > 0 {
                        Text("\(option.count)")
                            .foregroundStyle(.secondary)
                    }
                }
                .swipeActions(edge: .leading) {
                    RenameStationeryButton { onRename(option) }
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    DeleteStationeryButton(option: option) { onDelete(option) }
                }
                .contextMenu {
                    RenameStationeryButton { onRename(option) }
                    DeleteStationeryButton(option: option) { onDelete(option) }
                }
            }
            if allowAdding && outbound {
                HStack {
                    TextField("Add…", text: $newEntry)
                        .focused(focused, equals: key.type)
                    if focused.wrappedValue == key.type {
                        Button(action: {
                            let newValue = newEntry.trimmingCharacters(in: .whitespacesAndNewlines)
                            withAnimation {
                                CustomStationery.addValue(newValue, toType: key, in: moc)
                                newEntry = ""
                                focused.wrappedValue = nil
                            }
                            onEntryAdded()
                        }) {
                            Text("Save")
                                .foregroundStyle(Color.accentColor)
                        }
                        .buttonStyle(.plain)
                        .disabled({
                            let trimmed = newEntry.trimmingCharacters(in: .whitespacesAndNewlines)
                            return trimmed.isEmpty || options.map { $0.name }.contains(trimmed)
                        }())
                    }
                }
            }
        }
    }
}
