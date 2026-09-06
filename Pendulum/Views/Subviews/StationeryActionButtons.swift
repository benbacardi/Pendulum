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
    /// `.destructive` gives a context-menu item its red text. Pass `nil` in a `.swipeActions`
    /// context instead: a destructive-role swipe button makes the system play its own
    /// swipe-to-delete collapse animation on tap, regardless of what `action` actually does —
    /// tearing down the row (and anything attached to it, like a confirmation dialog) before
    /// the action's confirmation can be answered.
    var role: ButtonRole? = .destructive
    let action: () -> Void

    var body: some View {
        if option.count == 0 || option.customType != nil {
            Button(role: role, action: action) {
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
