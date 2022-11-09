//
//  SettingsList.swift
//  Pendulum
//
//  Created by Alex Faber on 05/11/2022.
//

import SwiftUI

struct SettingsList: View {
    @State private var enableNotifications = false
    @State private var enableEllen = false

    
    var body: some View {
        NavigationView {
            Form {
                Section(
                    header:Text("General"))
                {
                    Toggle("Notifications", isOn: $enableNotifications)
                    Toggle("Ellen", isOn: $enableEllen)
                }
                Section(
                    footer: Text("\(Bundle.main.appName) \(Bundle.main.appVersionNumber) (Build \(Bundle.main.appBuildNumber))\n**A Faber & Cardy Production**\n\nFor Ellen, adequately ginger, but perfectly lovely")
                        .fullWidth(alignment: .center)
                ){}
            }
            
            .navigationTitle(Text("Settings"))
        }
    }
    
}

struct SettingsList_Previews: PreviewProvider {
    static var previews: some View {
        SettingsList()
    }
}

