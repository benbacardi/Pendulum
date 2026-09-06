//
//  AddStationeryTypeForm.swift
//  Pendulum
//
//  Created by Ben Cardy on 21/11/2022.
//

import SwiftUI

struct AddStationeryTypeForm: View {
    @State private var typeName: String = ""
    @State private var icon: String = "envelope"
    @State private var showPicker: Bool = false
    @Environment(\.managedObjectContext) private var moc
    @State private var existingTypeNames: [String] = []
    let initial: CustomStationeryType?
    let done: (CustomStationeryType) -> ()

    var isDuplicate: Bool {
        let trimmed = typeName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return existingTypeNames.contains { $0.lowercased() == trimmed }
    }

    @ViewBuilder
    var iconHeader: some View {
        HStack {
            Spacer()
            Button(action: { showPicker = true }) {
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 80, height: 80)
                        Image(systemName: icon)
                            .font(.system(size: 32))
                            .foregroundStyle(.white)
                    }
                    Text("Change Icon")
                        .font(.caption)
                }
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .padding(.bottom)
        .textCase(nil)
    }

    var body: some View {
        Form {
            Section(header: iconHeader) {
                TextField("Name", text: $typeName)
                if isDuplicate {
                    Text("A category with this name already exists.")
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }
            Section {
                Button(action: {
                    let type = CustomStationeryType(type: typeName, icon: icon, value: "")
                    done(type)
                }) {
                    Text(initial == nil ? "Add" : "Update")
                        .fullWidth(alignment: .center)
                }
                .disabled(typeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isDuplicate)
            }
        }
        .sheet(isPresented: $showPicker) {
            SymbolPicker(selectedSymbol: $icon) {
                showPicker = false
            }
        }
        .task {
            if let initial {
                self.typeName = initial.type
                self.icon = initial.icon
            }
            // Fetch all existing types except the current one (if editing)
            let allTypes = CustomStationery.fetchDistinctTypes(from: moc).map { $0.type }
            if let initial {
                self.existingTypeNames = allTypes.filter { $0.caseInsensitiveCompare(initial.type) != .orderedSame }
            } else {
                self.existingTypeNames = allTypes
            }
        }
    }
}
