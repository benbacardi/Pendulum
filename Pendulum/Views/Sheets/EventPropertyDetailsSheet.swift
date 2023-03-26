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
    
    @AppStorage(UserDefaults.Key.sortStationeryAlphabetically.rawValue, store: UserDefaults.shared) private var sortAlphabetically: Bool = false
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
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
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
            if allowAdding && outbound {
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
                .background(Color(uiColor: .systemGroupedBackground))
            }
            .navigationTitle("Stationery")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        withAnimation {
                            self.sortAlphabetically.toggle()
                        }
                    }) {
                        Label("Sort Alphabetically", systemImage: self.sortAlphabetically ? "textformat.123" : "textformat")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Close")
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
        }
        
    }
    
    private func updateStationery() {
        pens = PenPal.fetchDistinctStationery(ofType: .pen, for: penpal, sortAlphabetically: self.sortAlphabetically, outbound: self.outbound)
        inks = PenPal.fetchDistinctStationery(ofType: .ink, for: penpal, sortAlphabetically: self.sortAlphabetically, outbound: self.outbound)
        papers = PenPal.fetchDistinctStationery(ofType: .paper, for: penpal, sortAlphabetically: self.sortAlphabetically, outbound: self.outbound)
    }
    
}
