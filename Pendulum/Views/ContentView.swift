//
//  ContentView.swift
//  Pendulum
//
//  Created by Ben Cardy on 04/11/2022.
//

import SwiftUI

struct ContentView: View {
    
    @State private var selectedTab: Int = Tab.penPalList.rawValue
    @StateObject private var appPreferences = AppPreferences.shared
    
    var body: some View {
        if DeviceType.isPad() {
            PenPalList(appPreferences: appPreferences)
        } else {
            TabView(selection: $selectedTab) {
                PenPalList(appPreferences: appPreferences)
                    .tabItem { Label("Pen Pals", systemImage: "pencil.line") }
                    .tag(Tab.penPalList.rawValue)
                SettingsList(appPreferences: appPreferences)
                    .tabItem { Label("Settings", systemImage: "gear") }
                    .tag(Tab.settings.rawValue)
//                Text("Debug")
//                    .tabItem { Label("Debug", systemImage: "ladybug") }
//                    .tag(3)
//                    .onAppear {
//                        Task {
//                            await AppDatabase.shared.test()
//                        }
//                    }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
