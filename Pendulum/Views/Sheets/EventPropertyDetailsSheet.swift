//
//  EventPropertyDetailsSheet.swift
//  Pendulum
//
//  Created by Ben Cardy on 10/11/2022.
//

import SwiftUI

struct ParameterCount: Comparable, Identifiable, CustomStringConvertible {
    let id = UUID()
    let name: String
    let count: Int
    let type: StationeryType
    
    static func < (lhs: ParameterCount, rhs: ParameterCount) -> Bool {
        if lhs.count != rhs.count {
            return lhs.count > rhs.count
        } else {
            return lhs.name < rhs.name
        }
    }
    
    static func == (lhs: ParameterCount, rhs: ParameterCount) -> Bool {
        return lhs.count == rhs.count && lhs.name == rhs.name
    }
    
    var description: String {
        "\(type.rawValue): \(name) (\(count))"
    }
    
}

struct EventPropertyDetailsSheet: View {
    
    // MARK: Environment
    @Environment(\.presentationMode) var presentationMode
    
    // MARK: Properties
    let penpal: PenPal?
    var allowAdding: Bool = false
    
    // MARK: State
    @State private var pens: [ParameterCount] = []
    @State private var inks: [ParameterCount] = []
    @State private var papers: [ParameterCount] = []
    
    @State private var newPenEntry: String = ""
    @FocusState private var newPenEntryIsFocused: Bool
    @State private var newInkEntry: String = ""
    @FocusState private var newInkEntryIsFocused: Bool
    @State private var newPaperEntry: String = ""
    @FocusState private var newPaperEntryIsFocused: Bool
    
    @State private var toDelete: ParameterCount? = nil
    @State private var showDeleteAlert: Bool = false
    
    @ViewBuilder
    func section(for type: StationeryType, with options: Binding<[ParameterCount]>, newEntry: Binding<String>, focused: FocusState<Bool>.Binding) -> some View {
        Section(header: HStack {
            Image(systemName: type.icon)
            Text(type.namePlural)
        }) {
            ForEach(options.wrappedValue, id: \.name) { option in
                HStack {
                    Text(option.name)
                        .fullWidth()
                    if option.count > 0 {
                        Text("\(option.count)")
                            .foregroundColor(.secondary)
                    }
                }
                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                    if option.count == 0 {
                        Button(action: {
                            self.toDelete = option
                            self.showDeleteAlert = true
                        }) {
                            Label("Delete", systemImage: "trash")
                        }
                        .tint(.red)
                    }
                }
            }
            if allowAdding {
                HStack {
                    TextField("Add…", text: newEntry)
                        .focused(focused)
                    if focused.wrappedValue {
                        Button(action: {
                            let stationery = Stationery(context: PersistenceController.shared.container.viewContext)
                            stationery.id = UUID()
                            stationery.value = newEntry.wrappedValue
                            stationery.type = type.recordType
                            withAnimation {
                                PersistenceController.shared.save()
                                options.wrappedValue.append(ParameterCount(name: stationery.wrappedValue, count: 0, type: type))
                                focused.wrappedValue = false
                                newEntry.wrappedValue = ""
                            }
                        }) {
                            Text("Save")
                                .foregroundColor(.accentColor)
                        }
                        .buttonStyle(.plain)
                        .disabled(newEntry.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || options.wrappedValue.map { $0.name }.contains(newEntry.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines)))
                    }
                }
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if pens.isEmpty && inks.isEmpty && papers.isEmpty && !allowAdding {
                    VStack {
                        if let image = UIImage(named: "undraw_monster_artist_2crm") {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: 200)
                                .padding(.bottom)
                        }
                        if let penpal = penpal {
                            Text("You haven't recorded any of the stationery you've used to write to \(penpal.wrappedName) yet!")
                                .fullWidth(alignment: .center)
                        } else {
                            Text("You haven't recorded any of the stationery you've used to write with yet!")
                                .fullWidth(alignment: .center)
                        }
                    }
                    .padding()
                } else {
                    List {
                        section(for: .pen, with: $pens, newEntry: $newPenEntry, focused: $newPenEntryIsFocused)
                        section(for: .ink, with: $inks, newEntry: $newInkEntry, focused: $newInkEntryIsFocused)
                        section(for: .paper, with: $papers, newEntry: $newPaperEntry, focused: $newPaperEntryIsFocused)
                    }
                    .confirmationDialog("Are you sure?", isPresented: $showDeleteAlert, titleVisibility: .visible, presenting: toDelete) { parameter in
                        Button("Delete \(parameter.name)", role: .destructive) {
                            Stationery.delete(parameter)
                            self.toDelete = nil
                            DispatchQueue.main.async {
                                withAnimation {
                                    switch parameter.type {
                                    case .pen:
                                        self.pens = self.pens.filter { $0 != parameter }
                                    case .ink:
                                        self.inks = self.inks.filter { $0 != parameter }
                                    case .paper:
                                        self.papers = self.papers.filter { $0 != parameter }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Stationery")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Close")
                    }
                }
            }
            .task {
                pens = PenPal.fetchDistinctStationery(ofType: .pen, for: penpal)
                inks = PenPal.fetchDistinctStationery(ofType: .ink, for: penpal)
                papers = PenPal.fetchDistinctStationery(ofType: .paper, for: penpal)
            }
        }
    }
}
