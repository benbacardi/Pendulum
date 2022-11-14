//
//  EventPropertyDetailsSheet.swift
//  Pendulum
//
//  Created by Ben Cardy on 10/11/2022.
//

import SwiftUI

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
    
    @ViewBuilder
    func section(for title: String, with options: Binding<[ParameterCount]>, icon: String, newEntry: Binding<String>, focused: FocusState<Bool>.Binding, recordType: String) -> some View {
        Section(header: HStack {
            Image(systemName: icon)
            Text(title)
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
            }
            if allowAdding {
                HStack {
                    TextField("Add…", text: newEntry)
                        .focused(focused)
                    if focused.wrappedValue {
                        Button(action: {
                            Task {
                                let record = Stationery(id: nil, type: recordType, value: newEntry.wrappedValue)
                                do {
                                    try await AppDatabase.shared.save(record)
                                    withAnimation {
                                        options.wrappedValue.append(ParameterCount(name: record.value, count: 0))
                                        focused.wrappedValue = false
                                        newEntry.wrappedValue = ""
                                    }
                                } catch {
                                    dataLogger.error("Could not save \(recordType)=\(newEntry.wrappedValue): \(error.localizedDescription)")
                                }
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
                            Text("You haven't recorded any of the stationery you've used to write to \(penpal.name) yet!")
                                .fullWidth(alignment: .center)
                        } else {
                            Text("You haven't recorded any of the stationery you've used to write with yet!")
                                .fullWidth(alignment: .center)
                        }
                    }
                    .padding()
                } else {
                    Form {
                        section(for: "Pens", with: $pens, icon: "pencil", newEntry: $newPenEntry, focused: $newPenEntryIsFocused, recordType: "pen")
                        section(for: "Inks", with: $inks, icon: "drop", newEntry: $newInkEntry, focused: $newInkEntryIsFocused, recordType: "ink")
                        section(for: "Paper", with: $papers, icon: "doc.plaintext", newEntry: $newPaperEntry, focused: $newPaperEntryIsFocused, recordType: "paper")
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
                pens = await AppDatabase.shared.fetchDistinctPens(for: penpal)
                inks = await AppDatabase.shared.fetchDistinctInks(for: penpal)
                papers = await AppDatabase.shared.fetchDistinctPapers(for: penpal)
            }
        }
    }
}

struct EventPropertyDetailsSheet_Previews: PreviewProvider {
    static var previews: some View {
        EventPropertyDetailsSheet(penpal: PenPal(id: "3", name: "Madi Van Houten", initials: "MV", image: nil, _lastEventType: EventType.written.rawValue, lastEventDate: Date(), notes: nil))
    }
}
