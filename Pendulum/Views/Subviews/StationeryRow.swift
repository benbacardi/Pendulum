//
//  StationeryRow.swift
//  Pendulum
//
//  Created by Ben Cardy on 10/11/2022.
//

import SwiftUI

/// One stationery entry row, shared by `StationeryTypeSection` and `CustomStationeryTypeSection`.
///
/// Owns its own delete-confirmation state so the `confirmationDialog` is attached directly to this
/// row rather than to some distant ancestor — it needs to be anchored to the specific row a person
/// swiped or long-pressed, not to the sheet as a whole.
struct StationeryRow: View {

    let option: ParameterCount
    let onRename: () -> Void
    let onDelete: () -> Void

    @State private var showDeleteConfirmation = false

    var body: some View {
        HStack {
            Text(option.name)
                .fullWidth()
            if option.count > 0 {
                Text("\(option.count)")
                    .foregroundStyle(.secondary)
            }
        }
        .swipeActions(edge: .leading) {
            RenameStationeryButton(action: onRename)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            DeleteStationeryButton(option: option, role: nil) {
                showDeleteConfirmation = true
            }
        }
        .contextMenu {
            RenameStationeryButton(action: onRename)
            DeleteStationeryButton(option: option) {
                showDeleteConfirmation = true
            }
        }
        .confirmationDialog("Are you sure?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete \(option.name)", role: .destructive, action: onDelete)
        }
    }
}
