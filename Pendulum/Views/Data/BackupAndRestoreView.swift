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
            ExportButton()
            RestoreButton()
        }
        .navigationTitle("Backup and Restore")
    }
}
