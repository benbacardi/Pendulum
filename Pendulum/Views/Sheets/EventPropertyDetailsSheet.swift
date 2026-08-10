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
    @Environment(\.presentationMode) var presentationMode
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

    @ViewBuilder
    func deleteButton(for option: ParameterCount) -> some View {
        if option.count == 0 || option.customType != nil {
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

    func customEntryDisabled(for key: CustomStationeryType, options: [ParameterCount]) -> Bool {
        let trimmed = (customNewEntries[key.type] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty || options.map { $0.name }.contains(trimmed)
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
                                options.wrappedValue.append(ParameterCount(name: stationery.wrappedValue, count: 0, type: type, customType: nil))
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

    @ViewBuilder
    func customSection(for key: CustomStationeryType, options: [ParameterCount]) -> some View {
        Section(header: HStack {
            Image(systemName: key.icon)
            Text(key.type)
            Spacer()
            Menu {
                Button(action: {
                    editingCustomStationery = key
                }) {
                    Label("Edit", systemImage: "pencil")
                }
                Button(role: .destructive, action: {
                    customTypeToDelete = key
                    showDeleteCustomTypeAlert = true
                }) {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Label("More actions", systemImage: "ellipsis")
                    .labelStyle(.iconOnly)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }) {
            if options.isEmpty && !(allowAdding && outbound) {
                Text("None recorded yet")
                    .foregroundColor(.secondary)
            }
            ForEach(options, id: \.name) { option in
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
                    TextField("Add…", text: Binding(
                        get: { customNewEntries[key.type] ?? "" },
                        set: { customNewEntries[key.type] = $0 }
                    ))
                    .focused($focusedCustomEntryType, equals: key.type)
                    if focusedCustomEntryType == key.type {
                        Button(action: {
                            let newValue = (customNewEntries[key.type] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                            withAnimation {
                                CustomStationery.addValue(newValue, toType: key, in: moc)
                                customNewEntries[key.type] = ""
                                focusedCustomEntryType = nil
                                self.updateStationery()
                            }
                        }) {
                            Text("Save")
                                .foregroundColor(.accentColor)
                        }
                        .buttonStyle(.plain)
                        .disabled(customEntryDisabled(for: key, options: options))
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
                        ForEach(Array(custom.keys).sorted(using: KeyPathComparator(\.type)), id: \.self) { key in
                            customSection(for: key, options: custom[key] ?? [])
                        }
                        Section {
                            Button(action: {
                                showAddStationerySheet = true
                            }) {
                                Text("Add stationery type…")
                            }
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
                            DispatchQueue.main.async {
                                withAnimation {
                                    if let type = parameter.type {
                                        switch type {
                                        case .pen:
                                            self.pens = self.pens.filter { $0 != parameter }
                                        case .ink:
                                            self.inks = self.inks.filter { $0 != parameter }
                                        case .paper:
                                            self.papers = self.papers.filter { $0 != parameter }
                                        }
                                    } else {
                                        self.updateStationery()
                                    }
                                }
                            }
                        }
                    }
                    .confirmationDialog("Delete this category and all its entries?", isPresented: $showDeleteCustomTypeAlert, titleVisibility: .visible, presenting: customTypeToDelete) { customType in
                        Button("Delete \(customType.type)", role: .destructive) {
                            CustomStationery.delete(customType, in: moc)
                            self.customTypeToDelete = nil
                            DispatchQueue.main.async {
                                withAnimation {
                                    self.updateStationery()
                                }
                            }
                        }
                        Button("Cancel", role: .cancel) {
                            self.customTypeToDelete = nil
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
            .sheet(isPresented: $showAddStationerySheet) {
                NavigationStack {
                    AddStationeryTypeForm(initial: nil) { newType in
                        self.showAddStationerySheet = false
                        CustomStationery.createType(newType, in: moc)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            withAnimation {
                                self.updateStationery()
                            }
                        }
                    }
                    .navigationTitle("Add Stationery Type")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
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
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            withAnimation {
                                self.updateStationery()
                            }
                        }
                    }
                    .navigationTitle("Edit Stationery Type")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
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

    private func updateStationery() {
        pens = PenPal.fetchDistinctStationery(ofType: .pen, for: penpal, sortAlphabetically: self.sortAlphabetically, outbound: self.outbound, from: moc)
        inks = PenPal.fetchDistinctStationery(ofType: .ink, for: penpal, sortAlphabetically: self.sortAlphabetically, outbound: self.outbound, from: moc)
        papers = PenPal.fetchDistinctStationery(ofType: .paper, for: penpal, sortAlphabetically: self.sortAlphabetically, outbound: self.outbound, from: moc)
        custom = PenPal.fetchDistinctCustomStationery(for: penpal, sortAlphabetically: self.sortAlphabetically, outbound: self.outbound, from: moc)
    }

}


struct EventPropertyDetailsSheet_Previews: PreviewProvider {
    static var previews: some View {
        EventPropertyDetailsSheet(penpal: nil)
    }
}
