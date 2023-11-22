//
//  ContentView.swift
//  Pendulum
//
//  Created by Ben Cardy on 04/11/2022.
//

import SwiftUI

struct ContentView: View {
    
    @Environment(\.managedObjectContext) var moc
    
    @State private var selectedTab: Tab = .penPalList
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
        .sheet(isPresented: $showWhatsNewOverlay) {
            WhatsNew()
        }
        .overlay {
            ImageGalleryOverlay()
        }
        .onAppear {
//            if lastLaunchedVersion != Bundle.main.appBuildNumber {
//                showWhatsNewOverlay = true
//                lastLaunchedVersion = Bundle.main.appBuildNumber
//            }
            if !UserDefaults.shared.hasGeneratedInitialBackup && UserDefaults.shared.exportURL == nil {
                UserDefaults.shared.hasGeneratedInitialBackup = true
                Task {
                    let exportService = ExportService()
                    UserDefaults.shared.exportURL = try? exportService.export(from: moc)
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
