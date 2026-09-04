//
//  NewPenPalList.swift
//  Pendulum
//
//  Created by Ben Cardy on 28/02/2023.
//

import SwiftUI
import MapKit

struct PenPalList: View {
    
    // MARK: Environment
    @EnvironmentObject private var router: Router
    @Environment(\.colorScheme) var colorScheme
    
    @Environment(\.managedObjectContext) var moc
    
    // MARK: State
    @State private var iconWidth: CGFloat = .zero
    @AppStorage(UserDefaults.Key.groupPenPalsInListView, store: UserDefaults.shared) private var groupPenPalsInListView: Bool = true
    @AppStorage(UserDefaults.Key.trackPostingLetters, store: UserDefaults.shared) private var trackPostingLetters: Bool = false
    @AppStorage(UserDefaults.Key.hideMap, store: UserDefaults.shared) private var hideMap: Bool = false
    
    @State private var cameraPosition: MapCameraPosition = .automatic
    
    var body: some View {
        /// Changed from a List to a scrolling LazyVStack, because List didn't properly update within the sections when the underlying Fetch Request data updated
        ScrollView {
            LazyVStack(spacing: 0) {
                if #available(iOS 26, *) {
                    Text("Pendulum")
                        .font(.largeTitle.bold())
                        .fullWidth()
                        .shadow(color: colorScheme == .dark ? .black : .white, radius: 1)
                        .padding([.bottom, .horizontal])
                }
                if groupPenPalsInListView {
                    ForEach(EventType.orderedCases) { eventType in
                        PenPalListSection(eventType: eventType, iconWidth: $iconWidth, trackPostingLetters: trackPostingLetters)
                            .padding(.horizontal)
                    }
                } else {
                    PenPalListSection(eventType: nil, iconWidth: $iconWidth, trackPostingLetters: trackPostingLetters)
                        .padding(.horizontal)
                }
            }
        }
        .onPreferenceChange(PenPalListIconWidthPreferenceKey.self) { value in
            self.iconWidth = value
        }
        .background {
            if #available(iOS 26, *) {
                if !hideMap {
                    Map(position: $cameraPosition, interactionModes: [])
                } else {
                    Color(.systemGroupedBackground)
                        .edgesIgnoringSafeArea(.all)
                }
            }
        }
        .task {
            if #available(iOS 26, *) {
                if !hideMap, let address = await Event.getLatestRelevantAddress(), let coord = address.location?.coordinate {
                    DispatchQueue.main.async {
                        self.cameraPosition = MapCameraPosition.region(.init(center: coord, span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 10)))
                    }
                }
            }
        }
    }
    
}

struct PenPalListIconWidthPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
