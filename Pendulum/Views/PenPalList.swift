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
    
    // MARK: State
    @State private var iconWidth: CGFloat = .zero
    @AppStorage(UserDefaults.Key.sortPenPalsAlphabetically.rawValue, store: UserDefaults.shared) private var sortPenPalsAlphabetically: Bool = false
    
    var body: some View {
        /// Changed from a List to a scrolling LazyVStack, because List didn't properly update within the sections when the underlying Fetch Request data updated
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(EventType.allCases) { eventType in
                    PenPalListSection(eventType: eventType, iconWidth: $iconWidth, trackPostingLetters: appPreferences.trackPostingLetters, sortAlphabetically: sortPenPalsAlphabetically)
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
