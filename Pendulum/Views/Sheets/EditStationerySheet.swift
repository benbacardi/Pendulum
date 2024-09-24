//
//  EditStationerySheet.swift
//  Pendulum
//
//  Created by Ben Cardy on 26/03/2023.
//

import SwiftUI

struct EditStationerySheet: View {
    
    @Environment(\.managedObjectContext) var moc
    
    // MARK: Properties
    let currentStationery: ParameterCount
    let outbound: Bool
    let done: () -> ()
    
    // MARK: Stationery
    @State private var changedStationery: String = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        Form {
            Section {
                TextField("Stationery", text: $changedStationery)
                    .focused($isFocused)
            } footer: {
                Label("Updating this \(currentStationery.type?.name.lowercased() ?? "stationery") will also update all previously logged correspondence that uses the \(currentStationery.type?.name.lowercased() ?? "stationery").", systemImage: "exclamationmark.triangle")
            }
            
            Section {
                Button(action: {
                    if let stationeryType = currentStationery.type {
                        Stationery.update(currentStationery, to: changedStationery.trimmingCharacters(in: .whitespacesAndNewlines), outbound: outbound, in: moc)
                    } else if let stationeryType = currentStationery.customType {
                        CustomStationery.update(currentStationery, to: changedStationery.trimmingCharacters(in: .whitespacesAndNewlines), in: moc)
                    }
                    done()
                }) {
                    Text("Update")
                        .fullWidth(alignment: .center)
                }
                .disabled(changedStationery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            
        }
        .onAppear {
            self.changedStationery = self.currentStationery.name
            self.isFocused = true
        }
    }
}

struct EditStationerySheet_Previews: PreviewProvider {
    static var previews: some View {
        EditStationerySheet(currentStationery: ParameterCount(name: "Foobar", count: 0, type: .ink, customType: nil), outbound: true) {
            
        }
    }
}
