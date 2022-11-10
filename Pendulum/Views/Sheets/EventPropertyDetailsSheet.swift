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
    let penpal: PenPal
    
    // MARK: State
    @State private var pens: [(String, Int)] = []
    @State private var inks: [(String, Int)] = []
    @State private var papers: [(String, Int)] = []
    
    @ViewBuilder
    func section(for title: String, with options: [(String, Int)], icon: String) -> some View {
        Section(header: HStack {
            Image(systemName: icon)
            Text(title)
        }) {
            ForEach(options, id: \.0) { (option, count) in
                HStack {
                    Text(option)
                        .fullWidth()
                    Text("\(count)")
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if pens.isEmpty && inks.isEmpty && papers.isEmpty {
                    VStack {
                        if let image = UIImage(named: "undraw_monster_artist_2crm") {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: 200)
                                .padding(.bottom)
                        }
                        Text("You haven't recorded any of the stationery you've used to write to \(penpal.name) yet!")
                            .fullWidth(alignment: .center)
                    }
                    .padding()
                } else {
                    Form {
                        if !pens.isEmpty {
                            section(for: "Pens", with: pens, icon: "pencil")
                        }
                        if !inks.isEmpty {
                            section(for: "Inks", with: inks, icon: "drop")
                        }
                        if !papers.isEmpty {
                            section(for: "Paper", with: papers, icon: "doc.plaintext")
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
            .onAppear {
                Task {
                    pens = await AppDatabase.shared.fetchDistinctPens(for: penpal)
                    inks = await AppDatabase.shared.fetchDistinctInks(for: penpal)
                    papers = await AppDatabase.shared.fetchDistinctPapers(for: penpal)
                }
            }
        }
    }
}

struct EventPropertyDetailsSheet_Previews: PreviewProvider {
    static var previews: some View {
        EventPropertyDetailsSheet(penpal: PenPal(id: "3", name: "Madi Van Houten", initials: "MV", image: nil, _lastEventType: EventType.written.rawValue, lastEventDate: Date(), notes: nil))
    }
}
