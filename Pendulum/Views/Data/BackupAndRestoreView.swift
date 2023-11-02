//
//  BackupAndRestoreView.swift
//  Pendulum
//
//  Created by Ben Cardy on 01/11/2023.
//

import SwiftUI

struct BackupAndRestoreView: View {
    var body: some View {
        Form {
            
            Section {
                ExportButton()
            } footer: {
                Text("Pendulum will export a single file containing all your Pen Pal data, including logged events, stationery, and photos. This file can be used to import your data back into the app at a later date. It can be quite large if you have many photos within the app.")
            }
            
            Section {
                RestoreButton()
            } footer: {
                Text("Import data from a previously exported backup file. The backup will be merged with the existing data in the app.")
            }
            
        }
        .navigationTitle("Backup and Restore")
    }
}
