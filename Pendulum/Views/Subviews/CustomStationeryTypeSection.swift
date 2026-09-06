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
    let onEditCategory: () -> Void
    /// Called after anything changes the underlying data — an entry added, an entry deleted, or
    /// the whole category deleted — so the parent can refetch.
    let onChanged: () -> Void

    @State private var showDeleteCategoryConfirmation = false

    var body: some View {
        Section(header: HStack {
            Image(systemName: key.icon)
            Text(key.type)
            Spacer()
            Menu {
                Button(action: onEditCategory) {
                    Label("Edit", systemImage: "pencil")
                }
                Button(role: .destructive) {
                    showDeleteCategoryConfirmation = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Label("More actions", systemImage: "ellipsis")
                    .labelStyle(.iconOnly)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .confirmationDialog("Delete this category and all its entries?", isPresented: $showDeleteCategoryConfirmation, titleVisibility: .visible) {
                Button("Delete \(key.type)", role: .destructive) {
                    CustomStationery.delete(key, in: moc)
                    onChanged()
                }
                Button("Cancel", role: .cancel) { }
            }
        }) {
            if options.isEmpty && !(allowAdding && outbound) {
                Text("None recorded yet")
                    .foregroundStyle(.secondary)
            }
            ForEach(options, id: \.name) { option in
                StationeryRow(option: option, onRename: { onRename(option) }) {
                    CustomStationery.delete(option, in: moc)
                    onChanged()
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
                            onChanged()
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
