//
//  EditStationerySheet.swift
//  Pendulum
//
//  Created by Ben Cardy on 26/03/2023.
//

import SwiftUI

struct EditStationerySheet: View {

    @Environment(\.managedObjectContext) var moc
    @Environment(\.presentationMode) var presentationMode

    // MARK: Properties
    let currentStationery: ParameterCount
    let outbound: Bool
    let done: () -> ()

    // MARK: Stationery
    @State private var changedStationery: String = ""
    @FocusState private var isFocused: Bool

    var typeDisplayName: String {
        currentStationery.type?.name ?? currentStationery.customType?.type ?? "Stationery"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Stationery", text: $changedStationery)
                        .focused($isFocused)
                } footer: {
                    Label("Updating this \(typeDisplayName.lowercased()) will also update all previously logged correspondence that uses the \(typeDisplayName.lowercased()).", systemImage: "exclamationmark.triangle")
                }
            }
            .onAppear {
                self.changedStationery = self.currentStationery.name
                self.isFocused = true
            }
            .navigationTitle("Update \(typeDisplayName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Label("Cancel", systemImage: "xmark")
                            .labelStyleIconOnlyOn26()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: {
                        let newValue = changedStationery.trimmingCharacters(in: .whitespacesAndNewlines)
                        if currentStationery.type != nil {
                            Stationery.update(currentStationery, to: newValue, outbound: outbound, in: moc)
                        } else if currentStationery.customType != nil {
                            CustomStationery.update(currentStationery, to: newValue, in: moc)
                        }
                        done()
                    }) {
                        Label("Save", systemImage: "checkmark")
                            .labelStyleIconOnlyOn26()
                    }
                    .disabled(changedStationery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }

        }
    }
}

struct EditStationerySheet_Previews: PreviewProvider {
    static var previews: some View {
        EditStationerySheet(currentStationery: ParameterCount(name: "Foobar", count: 0, type: .ink, customType: nil), outbound: true) {

        }
    }
}
