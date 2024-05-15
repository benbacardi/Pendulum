//
//  NewPenPalList.swift
//  Pendulum
//
//  Created by Ben Cardy on 28/02/2023.
//

import SwiftUI

struct PenPalList: View {
    
    // MARK: Environment
    @EnvironmentObject var appPreferences: AppPreferences
    @EnvironmentObject private var router: Router
    
    @Environment(\.managedObjectContext) var moc
    
    // MARK: State
    @State private var iconWidth: CGFloat = .zero
    @AppStorage(UserDefaults.Key.sortPenPalsAlphabetically, store: UserDefaults.shared) private var sortPenPalsAlphabetically: Bool = false
    @AppStorage(UserDefaults.Key.groupPenPalsInListView, store: UserDefaults.shared) private var groupPenPalsInListView: Bool = true
    @AppStorage(UserDefaults.Key.trackPostingLetters, store: UserDefaults.shared) private var trackPostingLetters: Bool = false
    
    var body: some View {
        /// Changed from a List to a scrolling LazyVStack, because List didn't properly update within the sections when the underlying Fetch Request data updated
        ScrollView {
            LazyVStack(spacing: 0) {
                if groupPenPalsInListView {
                    ForEach(EventType.allCases) { eventType in
                        PenPalListSection(eventType: eventType, iconWidth: $iconWidth, trackPostingLetters: trackPostingLetters, sortAlphabetically: sortPenPalsAlphabetically)
                            .padding(.horizontal)
                    }
                } else {
                    PenPalListSection(eventType: nil, iconWidth: $iconWidth, trackPostingLetters: trackPostingLetters, sortAlphabetically: sortPenPalsAlphabetically)
                        .padding(.horizontal)
                }
            }
        }
        .onPreferenceChange(PenPalListIconWidthPreferenceKey.self) { value in
            self.iconWidth = value
        }
    }
    
}

struct PenPalListIconWidthPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
