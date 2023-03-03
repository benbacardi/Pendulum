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
    
    let eventType: EventType
    
    // MARK: Environment
    @EnvironmentObject private var router: Router
    
    // MARK: State
    @FetchRequest var penpals: FetchedResults<PenPal>
    @Binding var iconWidth: CGFloat
    @State private var currentPenPal: PenPal? = nil
    @State private var showDeleteAlert = false
    
    init(eventType: EventType, iconWidth: Binding<CGFloat>, trackPostingLetters: Bool, sortAlphabetically: Bool = false) {
        self.eventType = eventType
        self._iconWidth = iconWidth
        
        var sortDescriptors: [NSSortDescriptor] = [
            NSSortDescriptor(key: "lastEventDate", ascending: false),
            NSSortDescriptor(key: "name", ascending: true)
        ]
        
        if sortAlphabetically {
            sortDescriptors.insert(NSSortDescriptor(key: "name", ascending: true), at: 0)
        }
        
        let predicate: NSCompoundPredicate
        
        /// If trackPostingLetters is false, we need to:
        ///  - group both .sent and .written penpals into the .sent section
        ///  - return no penpals for .written
        
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
        
        self._penpals = FetchRequest<PenPal>(
            sortDescriptors: sortDescriptors,
            predicate: predicate,
            animation: .default
        )
    }
    
    @ViewBuilder
    var sectionHeader: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(eventType.color)
                    .frame(width: iconWidth * 1.5, height: iconWidth * 1.5)
                Image(systemName: eventType.phraseIcon)
                    .font(Font.caption.weight(.bold))
                    .foregroundColor(.white)
                    .background(GeometryReader { geo in
                        Color.clear.preference(key: PenPalListIconWidthPreferenceKey.self, value: max(geo.size.width, geo.size.height))
                    })
            }
            Text(eventType.phrase)
                .fullWidth()
                .font(.body)
                .foregroundColor(.primary)
        }
    }
    
    var body: some View {
        if !penpals.isEmpty {
            sectionHeader
            ForEach(penpals) { penpal in
                Button(action: {
                    router.replace(with: .penPalDetail(penpal: penpal))
                }) {
                    PenPalListItem(penpal: penpal)
                }
                .animation(.default, value: penpal)
                .swipeActions {
                    Button(action: {
                        withAnimation {
                            penpal.archive(!penpal.archived)
                        }
                    }) {
                        Label(penpal.archived ? "Unarchive" : "Archive", systemImage: "archivebox")
                    }
                }
                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                    Button(action: {
                        self.currentPenPal = penpal
                        self.showDeleteAlert = true
                    }) {
                        Label("Delete", systemImage: "trash")
                    }
                    .tint(.red)
                }
                .confirmationDialog("Are you sure?", isPresented: $showDeleteAlert, titleVisibility: .visible, presenting: currentPenPal) { penpal in
                    Button("Delete \(penpal.wrappedName)", role: .destructive) {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            penpal.delete()
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
            }
        } else {
            EmptyView()
        }
    }
    
}
