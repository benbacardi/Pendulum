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
    @Environment(\.managedObjectContext) var moc
    
    // MARK: Properties
    let penpal: PenPal?
    var allowAdding: Bool = false
    
    // MARK: State
    @State private var pens: [ParameterCount] = []
    @State private var inks: [ParameterCount] = []
    @State private var papers: [ParameterCount] = []
    
    @State private var editingStationery: ParameterCount? = nil
    
    @AppStorage(UserDefaults.Key.sortStationeryAlphabetically, store: UserDefaults.shared) private var sortAlphabetically: Bool = false
    @State private var outbound: Bool = true
    
    @State private var newPenEntry: String = ""
    @FocusState private var newPenEntryIsFocused: Bool
    @State private var newInkEntry: String = ""
    @FocusState private var newInkEntryIsFocused: Bool
    @State private var newPaperEntry: String = ""
    @FocusState private var newPaperEntryIsFocused: Bool
    
    @State private var toDelete: ParameterCount? = nil
    @State private var showDeleteAlert: Bool = false
    
    @ViewBuilder
    func deleteButton(for option: ParameterCount) -> some View {
        if option.count == 0 {
            Button(role: .destructive) {
                self.toDelete = option
                self.showDeleteAlert = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
            .tint(.red)
        } else {
            EmptyView()
        }
    }
    
    @ViewBuilder
    func editButton(for option: ParameterCount) -> some View {
        Button(action: {
            self.editingStationery = option
        }) {
            Label("Edit", systemImage: "pencil")
        }
    }
    
    @ViewBuilder
    func section(for type: StationeryType, with options: Binding<[ParameterCount]>, newEntry: Binding<String>, focused: FocusState<Bool>.Binding) -> some View {
        Section(header: HStack {
            Image(systemName: type.icon)
            Text(type.namePlural)
        }) {
            if options.wrappedValue.isEmpty && !(allowAdding && outbound) {
                Text("None recorded yet")
                    .foregroundColor(.secondary)
            }
            ForEach(options.wrappedValue, id: \.name) { option in
                HStack {
                    Text(option.name)
                        .fullWidth()
                    if option.count > 0 {
                        Text("\(option.count)")
                            .foregroundColor(.secondary)
                    }
                }
                .swipeActions(edge: .leading) {
                    editButton(for: option)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    deleteButton(for: option)
                }
                .contextMenu {
                    editButton(for: option)
                    deleteButton(for: option)
                }
            }
            if allowAdding && outbound {
                HStack {
                    TextField("Add…", text: newEntry)
                        .focused(focused)
                    if focused.wrappedValue {
                        Button(action: {
                            let stationery = Stationery(context: moc)
                            stationery.id = UUID()
                            stationery.value = newEntry.wrappedValue
                            stationery.type = type.recordType
                            withAnimation {
                                PersistenceController.shared.save(context: moc)
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
                VStack(spacing: 0) {
                    Picker("Direction", selection: $outbound) {
                        Text("Sent").tag(true)
                        Text("Received").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.bottom)
                    List {
                        section(for: .pen, with: $pens, newEntry: $newPenEntry, focused: $newPenEntryIsFocused)
                        section(for: .ink, with: $inks, newEntry: $newInkEntry, focused: $newInkEntryIsFocused)
                        section(for: .paper, with: $papers, newEntry: $newPaperEntry, focused: $newPaperEntryIsFocused)
                    }
                    .confirmationDialog("Are you sure?", isPresented: $showDeleteAlert, titleVisibility: .visible, presenting: toDelete) { parameter in
                        Button("Delete \(parameter.name)", role: .destructive) {
                            Stationery.delete(parameter, in: moc)
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
                .background(Color(uiColor: .systemGroupedBackground))
            }
            .navigationTitle("Stationery")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        withAnimation {
                            self.sortAlphabetically.toggle()
                        }
                    }) {
                        Label("Sort Alphabetically", systemImage: self.sortAlphabetically ? "textformat.123" : "textformat")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Label("Close", systemImage: "xmark")
                            .labelStyleIconOnlyOn26()
                    }
                }
            }
            .task {
                self.updateStationery()
            }
            .onChange(of: sortAlphabetically) { _ in
                withAnimation {
                    self.updateStationery()
                }
            }
            .onChange(of: outbound) { _ in
                withAnimation {
                    self.updateStationery()
                }
            }
            .sheet(item: $editingStationery) { item in
                EditStationerySheet(currentStationery: item, outbound: outbound) {
                    self.editingStationery = nil
                    withAnimation {
                        dataLogger.debug("Updating!")
                        self.updateStationery()
                    }
                }
            }
        }
        
    }
    
    private func updateStationery() {
        pens = PenPal.fetchDistinctStationery(ofType: .pen, for: penpal, sortAlphabetically: self.sortAlphabetically, outbound: self.outbound, from: moc)
        inks = PenPal.fetchDistinctStationery(ofType: .ink, for: penpal, sortAlphabetically: self.sortAlphabetically, outbound: self.outbound, from: moc)
        papers = PenPal.fetchDistinctStationery(ofType: .paper, for: penpal, sortAlphabetically: self.sortAlphabetically, outbound: self.outbound, from: moc)
    }
    
}


struct EventPropertyDetailsSheet_Previews: PreviewProvider {
    static var previews: some View {
        EventPropertyDetailsSheet(penpal: nil)
    }
}
