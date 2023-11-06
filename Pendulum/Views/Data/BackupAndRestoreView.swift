//
//  BackupAndRestoreView.swift
//  Pendulum
//
//  Created by Ben Cardy on 01/11/2023.
//

import SwiftUI

struct BackupAndRestoreView: View {
    
    @State private var lastBackup: Backup? = nil
    
    var body: some View {
        Form {
            ExportButton(backup: $lastBackup)
            RestoreButton(backup: $lastBackup)
        }
        .task {
            if let url = UserDefaults.shared.exportURL {
                self.lastBackup = Backup(url: url)
            }
        }
        .navigationTitle("Backup and Restore")
    }
}
