//
//  ContentView.swift
//  Pendulum
//
//  Created by Ben Cardy on 04/11/2022.
//

import SwiftUI

struct ContentView: View {
    
    @State private var selectedTab: Tab = .penPalList
    @StateObject private var appPreferences = AppPreferences.shared
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @EnvironmentObject var imageViewerController: ImageViewerController
    @State private var showWhatsNewOverlay: Bool = false
    @AppStorage(UserDefaults.Key.lastLaunchedVersion.rawValue, store: UserDefaults.shared) private var lastLaunchedVersion: String = ""
        
    var body: some View {
        Group {
            if DeviceType.isPad() && horizontalSizeClass != .compact {
                PenPalSplitView()
            } else {
                TabView(selection: $selectedTab) {
                    PenPalTab()
                        .tabItem { Label("Pen Pals", systemImage: "pencil.line") }
                        .tag(Tab.penPalList)
                    SettingsList()
                        .tabItem { Label("Settings", systemImage: "gear") }
                        .tag(Tab.settings)
                }
            }
        }
        .environmentObject(appPreferences)
        .sheet(isPresented: $showWhatsNewOverlay) {
            WhatsNew()
        }
        .overlay {
            ImageGalleryOverlay()
        }
        .onAppear {
            if lastLaunchedVersion != Bundle.main.appBuildNumber {
//                showWhatsNewOverlay = true
                lastLaunchedVersion = Bundle.main.appBuildNumber
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
