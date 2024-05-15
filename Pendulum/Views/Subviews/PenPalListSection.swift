//
//  PenPalListSection.swift
//  Pendulum
//
//  Created by Ben Cardy on 01/03/2023.
//

import SwiftUI
import Contacts

let EMPTY_PREDICATE = NSCompoundPredicate(type: .and, subpredicates: [NSPredicate(value: false)])

struct PenPalListSection: View {
    
    let eventType: EventType?
    
    // MARK: Environment
    @EnvironmentObject private var router: Router
    @Environment(\.managedObjectContext) var moc
    
    // MARK: State
    @FetchRequest var penpals: FetchedResults<PenPal>
    @Binding var iconWidth: CGFloat
    @State private var currentPenPal: PenPal? = nil
    @State private var showDeleteAlert = false
        
    init(eventType: EventType?, iconWidth: Binding<CGFloat>, trackPostingLetters: Bool, sortAlphabetically: Bool = false) {
        self.eventType = eventType
        self._iconWidth = iconWidth
        
        var sortDescriptors: [NSSortDescriptor] = [
            NSSortDescriptor(key: "lastEventDate", ascending: false),
            NSSortDescriptor(key: "name", ascending: true)
        ]
        
        let predicate: NSCompoundPredicate?
        
        /// If trackPostingLetters is false, we need to:
        ///  - group both .sent and .written penpals into the .sent section
        ///  - return no penpals for .written
        
        if let eventType {
            
            switch eventType {
            case .written:
                if trackPostingLetters {
                    predicate = EventType.written.lastPredicate
                } else {
                    predicate = EMPTY_PREDICATE
                }
            case .sent:
                if trackPostingLetters {
                    predicate = NSCompoundPredicate(type: .or, subpredicates: [
                        EventType.sent.lastPredicate,
                        EventType.theyReceived.lastPredicate,
                    ])
                } else {
                    predicate = NSCompoundPredicate(type: .or, subpredicates: [
                        EventType.sent.lastPredicate,
                        EventType.theyReceived.lastPredicate,
                        EventType.written.lastPredicate
                    ])
                }
            case .theyReceived:
                predicate = EMPTY_PREDICATE
            default:
                predicate = eventType.lastPredicate
            }
            
        } else {
            predicate = nil
        }
        
        if sortAlphabetically || eventType == .archived {
            sortDescriptors.insert(NSSortDescriptor(key: "name", ascending: true), at: 0)
        }
        
        if eventType == nil {
            sortDescriptors.insert(NSSortDescriptor(key: "archived", ascending: true), at: 0)
        }
        
        self._penpals = FetchRequest<PenPal>(
            sortDescriptors: sortDescriptors,
            predicate: predicate,
            animation: .default
        )
    }
    
    @ViewBuilder
    var sectionHeader: some View {
        if let eventType {
            HStack {
                eventType.sectionHeaderIcon
                    .font(.title)
                Text(eventType.phrase)
                    .fullWidth()
                    .font(.body)
                    .foregroundColor(.primary)
            }
        } else {
            EmptyView()
        }
    }
    
    @ViewBuilder
    func sendButton(for penpal: PenPal) -> some View {
        Button(action: {
            withAnimation {
                penpal.sendLastWrittenEvent(in: moc)
            }
        }) {
            Label("I've Posted This", systemImage: EventType.sent.icon)
        }
    }
    
    @ViewBuilder
    func archiveButton(for penpal: PenPal) -> some View {
        Button(action: {
            withAnimation {
                penpal.archive(!penpal.archived, in: moc)
            }
        }) {
            Label(penpal.archived ? "Unarchive" : "Archive", systemImage: "archivebox")
        }
    }
    
    @ViewBuilder
    func deleteButton(for penpal: PenPal) -> some View {
        Button(role: .destructive) {
            self.currentPenPal = penpal
            self.showDeleteAlert = true
        } label: {
            Label("Delete", systemImage: "trash")
        }
        .tint(.red)
    }
    
    var body: some View {
        if !penpals.isEmpty {
            sectionHeader
                .padding(.bottom, 8)
            ForEach(penpals) { penpal in
                Button(action: {
                    router.replace(with: .penPalDetail(penpal: penpal))
                }) {
                    PenPalListItem(penpal: penpal)
                }
                .animation(.default, value: penpal)
                .contextMenu {
                    if penpal.groupingEventType == .written {
                        sendButton(for: penpal)
                        Divider()
                    }
                    archiveButton(for: penpal)
                    deleteButton(for: penpal)
                }
                .confirmationDialog("Are you sure?", isPresented: $showDeleteAlert, titleVisibility: .visible, presenting: currentPenPal) { penpal in
                    Button("Delete \(penpal.wrappedName)", role: .destructive) {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            penpal.delete(in: moc)
                            if let path = router.path.first {
                                switch path {
                                case let .penPalDetail(pathPenPal):
                                    if pathPenPal == penpal {
                                        router.path.removeFirst()
                                    }
                                }
                            }
                            self.currentPenPal = nil
                        }
                    }
                }
                .padding(.bottom, 8)
            }
            Spacer().frame(height: 10)
        } else {
            EmptyView()
        }
    }
    
}
