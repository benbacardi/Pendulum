//
//  ManualAddPenPalSheet.swift
//  Pendulum
//
//  Created by Ben Cardy on 26/11/2022.
//

import SwiftUI

struct ManualAddPenPalSheet: View {
    
    // MARK: Environment
    @Environment(\.managedObjectContext) var moc
    @Environment(\.presentationMode) var presentationMode
    
    // MARK: State
    @State private var name: String = ""
    
    // MARK: Parameters
    var done: (() -> ())? = nil
    
    var initials: String {
        if name.isEmpty {
            return "?"
        }
        let parts = name.split(separator: " ")
        if parts.count == 1 {
            return "\(name.prefix(1))".uppercased()
        }
        if let first = parts.first, let last = parts.last {
            return "\(first.prefix(1))\(last.prefix(1))".uppercased()
        }
        return "??"
    }
    
    @ViewBuilder
    var sectionHeader: some View {
        HStack {
            Spacer()
            ZStack {
                Circle()
                    .fill(.gray)
                Text(initials)
                    .font(.system(.title, design: .rounded))
                    .bold()
                    .foregroundColor(.white)
            }
            .frame(width: 60, height: 60)
            Spacer()
        }
        .padding(.bottom)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: sectionHeader) {
                    TextField("Name", text: $name)
                }
            }
            .navigationBarTitle("Add Pen Pal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Cancel")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            let newPenPal = PenPal(context: moc)
                            newPenPal.id = UUID()
                            newPenPal.name = name
                            newPenPal.initials = initials
                            newPenPal.image = nil
                            newPenPal.lastEventType = EventType.noEvent
                            do {
                                try moc.save()
                                if let done = done {
                                    done()
                                } else {
                                    presentationMode.wrappedValue.dismiss()
                                }
                            } catch {
                                dataLogger.error("Could not save manual PenPal: \(error.localizedDescription)")
                            }
                        }
                    }) {
                        Text("Add")
                    }
                    .disabled(self.name.isEmpty)
                }
            }
        }
    }
}

struct ManualAddPenPalSheet_Previews: PreviewProvider {
    static var previews: some View {
        ManualAddPenPalSheet()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
