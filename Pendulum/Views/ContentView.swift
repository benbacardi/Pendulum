//
//  ContentView.swift
//  Pendulum
//
//  Created by Ben Cardy on 04/11/2022.
//

import SwiftUI
import ImageViewer

struct ContentView: View {
    
    @State private var selectedTab: Int = Tab.penPalList.rawValue
    @State private var showImageViewer: Bool = false
    @State private var image: Image? = nil
    
    var body: some View {
        if DeviceType.isPad() {
            PenPalList(showImageViewer: $showImageViewer, image: $image)
                .overlay(ImageViewer(image: $image, viewerShown: $showImageViewer, closeButtonTopRight: true))
        } else {
            TabView(selection: $selectedTab) {
                PenPalList(showImageViewer: $showImageViewer, image: $image)
                    .tabItem { Label("Pen Pals", systemImage: "pencil.line") }
                    .tag(Tab.penPalList.rawValue)
                SettingsList()
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
            .overlay(ImageViewer(image: $image, viewerShown: $showImageViewer, closeButtonTopRight: true))
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
