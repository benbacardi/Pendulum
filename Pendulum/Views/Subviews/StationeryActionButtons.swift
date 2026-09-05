//
//  StationeryActionButtons.swift
//  Pendulum
//
//  Created by Ben Cardy on 10/11/2022.
//

import SwiftUI

/// Shown for a stationery row that hasn't been used yet, or a custom-type entry — used ones stay
/// so past events keep an accurate record of what was actually used.
struct DeleteStationeryButton: View {

    let option: ParameterCount
    let action: () -> Void

    var body: some View {
        if option.count == 0 || option.customType != nil {
            Button(role: .destructive, action: action) {
                Label("Delete", systemImage: "trash")
            }
            .tint(.red)
        } else {
            EmptyView()
        }
    }
}

struct RenameStationeryButton: View {

    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("Rename", systemImage: "pencil")
        }
    }
}
