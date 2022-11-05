//
//  ContentView.swift
//  Pendulum
//
//  Created by Ben Cardy on 04/11/2022.
//

import SwiftUI

struct ContentView: View {
    
    @State private var selectedTab: Int = Tab.penPalList.rawValue
    
    var body: some View {
        TabView(selection: $selectedTab) {
            PenPalList()
                .tabItem { Label("Pen Pals", systemImage: "pencil.line") }
                .tag(Tab.penPalList.rawValue)
            SettingsList()
                .tabItem { Label("Ellen", systemImage: "tortoise") }
                .tag(Tab.settings.rawValue)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
