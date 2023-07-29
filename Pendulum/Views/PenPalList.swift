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
    @AppStorage(UserDefaults.Key.refreshId.rawValue) private var refreshId: String = UUID().uuidString
    
    var body: some View {
        List {
            ForEach(EventType.allCases) { eventType in
                PenPalListSection(eventType: eventType, iconWidth: $iconWidth, trackPostingLetters: appPreferences.trackPostingLetters, sortAlphabetically: sortPenPalsAlphabetically)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                    .padding(.horizontal)
                    .padding(.vertical, 5)
                    .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .onPreferenceChange(PenPalListIconWidthPreferenceKey.self) { value in
            self.iconWidth = value
        }
        .id(refreshId)
    }
    
}

struct PenPalListIconWidthPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
