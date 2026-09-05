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
    let type: StationeryType?
    let customType: CustomStationeryType?

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

    var typeName: String {
        type?.rawValue ?? customType?.type ?? "unknown"
    }

    var description: String {
        "\(typeName): \(name) (\(count))"
    }

    var icon: String {
        type?.icon ?? customType?.icon ?? "pencil"
    }

}

struct EventPropertyDetailsSheet: View {

    // MARK: Environment
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) var moc

    // MARK: Properties
    let penpal: PenPal?
    var allowAdding: Bool = false

    // MARK: State
    @State private var pens: [ParameterCount] = []
    @State private var inks: [ParameterCount] = []
    @State private var papers: [ParameterCount] = []
    @State private var custom: [CustomStationeryType: [ParameterCount]] = [:]

    @State private var editingStationery: ParameterCount? = nil
    @State private var editingCustomStationery: CustomStationeryType? = nil

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

    @State private var customTypeToDelete: CustomStationeryType? = nil
    @State private var showDeleteCustomTypeAlert: Bool = false

    @State private var showAddStationerySheet: Bool = false

    @State private var customNewEntries: [String: String] = [:]
    @FocusState private var focusedCustomEntryType: String?

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
                        StationeryTypeSection(type: .pen, options: $pens, newEntry: $newPenEntry, focused: $newPenEntryIsFocused, allowAdding: allowAdding, outbound: outbound, onRename: rename, onDelete: delete)
                        StationeryTypeSection(type: .ink, options: $inks, newEntry: $newInkEntry, focused: $newInkEntryIsFocused, allowAdding: allowAdding, outbound: outbound, onRename: rename, onDelete: delete)
                        StationeryTypeSection(type: .paper, options: $papers, newEntry: $newPaperEntry, focused: $newPaperEntryIsFocused, allowAdding: allowAdding, outbound: outbound, onRename: rename, onDelete: delete)
                        ForEach(Array(custom.keys).sorted(using: KeyPathComparator(\.type)), id: \.self) { key in
                            CustomStationeryTypeSection(
                                key: key,
                                options: custom[key] ?? [],
                                newEntry: Binding(
                                    get: { customNewEntries[key.type] ?? "" },
                                    set: { customNewEntries[key.type] = $0 }
                                ),
                                focused: $focusedCustomEntryType,
                                allowAdding: allowAdding,
                                outbound: outbound,
                                onRename: rename,
                                onDelete: delete,
                                onEditCategory: { editingCustomStationery = key },
                                onDeleteCategory: {
                                    customTypeToDelete = key
                                    showDeleteCustomTypeAlert = true
                                },
                                onEntryAdded: { Task { await self.updateStationery() } }
                            )
                        }
                    }
                    .confirmationDialog("Are you sure?", isPresented: $showDeleteAlert, titleVisibility: .visible, presenting: toDelete) { parameter in
                        Button("Delete \(parameter.name)", role: .destructive) {
                            if parameter.type != nil {
                                Stationery.delete(parameter, in: moc)
                            } else if parameter.customType != nil {
                                CustomStationery.delete(parameter, in: moc)
                            }
                            self.toDelete = nil
                            if let type = parameter.type {
                                withAnimation {
                                    switch type {
                                    case .pen:
                                        self.pens = self.pens.filter { $0 != parameter }
                                    case .ink:
                                        self.inks = self.inks.filter { $0 != parameter }
                                    case .paper:
                                        self.papers = self.papers.filter { $0 != parameter }
                                    }
                                }
                            } else {
                                Task {
                                    await self.updateStationery()
                                }
                            }
                        }
                    }
                    .confirmationDialog("Delete this category and all its entries?", isPresented: $showDeleteCustomTypeAlert, titleVisibility: .visible, presenting: customTypeToDelete) { customType in
                        Button("Delete \(customType.type)", role: .destructive) {
                            CustomStationery.delete(customType, in: moc)
                            self.customTypeToDelete = nil
                            Task {
                                await self.updateStationery()
                            }
                        }
                        Button("Cancel", role: .cancel) {
                            self.customTypeToDelete = nil
                        }
                    }
                }
                .background(Color(.systemGroupedBackground))
            }
            .navigationTitle("Stationery")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Section("Sort") {
                            Button(action: {
                                withAnimation {
                                    self.sortAlphabetically = true
                                }
                            }) {
                                if sortAlphabetically {
                                    Label("Alphabetically", systemImage: "checkmark")
                                } else {
                                    Text("Alphabetically")
                                }
                            }
                            Button(action: {
                                withAnimation {
                                    self.sortAlphabetically = false
                                }
                            }) {
                                if !sortAlphabetically {
                                    Label("By Count", systemImage: "checkmark")
                                } else {
                                    Text("By Count")
                                }
                            }
                        }
                    } label: {
                        Label("Sort", systemImage: "slider.horizontal.3")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        showAddStationerySheet = true
                    }) {
                        Label("Add Stationery Type", systemImage: "plus")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Label("Close", systemImage: "xmark")
                            .labelStyleIconOnlyOn26()
                    }
                }
            }
            .task(id: stationeryQuery) {
                await self.updateStationery()
            }
            .sheet(item: $editingStationery) { item in
                EditStationerySheet(currentStationery: item, outbound: outbound) {
                    self.editingStationery = nil
                    dataLogger.debug("Updating!")
                    Task {
                        await self.updateStationery()
                    }
                }
            }
            .sheet(isPresented: $showAddStationerySheet) {
                NavigationStack {
                    AddStationeryTypeForm(initial: nil) { newType in
                        self.showAddStationerySheet = false
                        CustomStationery.createType(newType, in: moc)
                        Task {
                            await self.updateStationery()
                        }
                    }
                    .navigationTitle("Add Stationery Type")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button(action: {
                                self.showAddStationerySheet = false
                            }) {
                                Label("Cancel", systemImage: "xmark")
                                    .labelStyleIconOnlyOn26()
                            }
                        }
                    }
                }
            }
            .sheet(item: $editingCustomStationery) { item in
                NavigationStack {
                    AddStationeryTypeForm(initial: item) { newItem in
                        self.editingCustomStationery = nil
                        CustomStationery.update(item, to: newItem, in: moc)
                        Task {
                            await self.updateStationery()
                        }
                    }
                    .navigationTitle("Edit Stationery Type")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button(action: {
                                self.editingCustomStationery = nil
                            }) {
                                Label("Cancel", systemImage: "xmark")
                                    .labelStyleIconOnlyOn26()
                            }
                        }
                    }
                }
            }
        }

    }

    /// The inputs the stationery lists depend on — both have to be watched, or changing the sort
    /// order or the direction leaves the previous lists on screen.
    private struct StationeryQuery: Equatable {
        let sortAlphabetically: Bool
        let outbound: Bool
    }
    
    private var stationeryQuery: StationeryQuery {
        StationeryQuery(sortAlphabetically: sortAlphabetically, outbound: outbound)
    }

    private func rename(_ option: ParameterCount) {
        self.editingStationery = option
    }

    private func delete(_ option: ParameterCount) {
        self.toDelete = option
        self.showDeleteAlert = true
    }

    private func updateStationery() async {
        let penpalID = penpal?.objectID
        let sortAlphabetically = self.sortAlphabetically
        let outbound = self.outbound
        let fetched = await PersistenceController.shared.fetching { context in
            let penpal: PenPal? = penpalID.flatMap { id in
                (try? context.existingObject(with: id)) as? PenPal
            }
            return (
                pens: PenPal.fetchDistinctStationery(ofType: .pen, for: penpal, sortAlphabetically: sortAlphabetically, outbound: outbound, from: context),
                inks: PenPal.fetchDistinctStationery(ofType: .ink, for: penpal, sortAlphabetically: sortAlphabetically, outbound: outbound, from: context),
                papers: PenPal.fetchDistinctStationery(ofType: .paper, for: penpal, sortAlphabetically: sortAlphabetically, outbound: outbound, from: context),
                custom: PenPal.fetchDistinctCustomStationery(for: penpal, sortAlphabetically: sortAlphabetically, outbound: outbound, from: context)
            )
        }
        withAnimation {
            self.pens = fetched.pens
            self.inks = fetched.inks
            self.papers = fetched.papers
            self.custom = fetched.custom
        }
    }

}


#Preview {
    EventPropertyDetailsSheet(penpal: nil)
}
