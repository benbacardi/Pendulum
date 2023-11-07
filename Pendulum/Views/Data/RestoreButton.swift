//
//  RestoreButton.swift
//  Pendulum
//
//  Created by Ben Cardy on 01/11/2023.
//

import SwiftUI

enum ImportState {
    case pending
    case inProgress
    case successful
    case error
}

struct RestoreButton: View {
    
    // MARK: Environment
    @Environment(\.managedObjectContext) var moc
    
    // MARK: State
    @Binding var backup: Backup?
    
    @State private var showFileImporter: Bool = false
    @State private var importState: ImportState = .pending
    @State private var importResult: ImportResult? = nil
    @State private var showImportResult: Bool = false
    @State private var overwrite: Bool = false
    @State private var lastArchive: URL? = nil
    
    @State private var showBackupChoice: Bool = false
    
    var footerText: String {
        var string = "Import data from a previously exported backup file. The backup will be merged with the existing data in the app,"
        if !overwrite {
            string = "\(string) not"
        }
        return "\(string) updating any duplicate Pen Pals and events."
    }
    
    var body: some View {
        Section {
            Button(action: restore) {
                HStack {
                    Text("Restore from Backup…")
                    Spacer()
                    switch importState {
                    case .pending, .successful:
                        EmptyView()
                    case .inProgress:
                        ProgressView()
                    case .error:
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundStyle(Color.red)
                    }
                }
            }
            .disabled(importState == .inProgress)
            Toggle("Overwrite Duplicates", isOn: $overwrite)
        } header: {
            Text("Restore")
        } footer: {
            Text(footerText)
        }
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.zip]) { result in
            switch result {
            case .success(let file):
                importURL(file)
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
        .onChange(of: showFileImporter) { newValue in
            if !showFileImporter && self.importState == .inProgress {
                self.importState = .pending
            }
        }
        .alert("Restore Complete", isPresented: $showImportResult, presenting: importResult) { importResult in
            
        } message: { importResult in
            Text("Restored ^[\(importResult.penPalCount) Pen Pal](inflect: true), ^[\(importResult.eventCount) event](inflect: true), ^[\(importResult.photoCount) photo](inflect: true), and ^[\(importResult.stationeryCount) stationery item](inflect: true).")
        }
        .confirmationDialog("Choose an archive", isPresented: $showBackupChoice, titleVisibility: .visible) {
            if let backup = backup {
                Button(action: {
                    importURL(backup.url)
                }) {
                    if let date = backup.url.creationDate {
                        Text(date, format: .dateTime)
                    } else {
                        Text(backup.name)
                    }
                }
            }
            Button(action: {
                self.showFileImporter = true
            }) {
                Text("Choose from Files")
            }
            Button("Cancel", role: .cancel) { self.changeImportState(to: .pending) }
        }
    }
    
    func importURL(_ url: URL) {
        do {
            self.importResult = try Export.restore(from: url, to: moc, overwritingExistingData: self.overwrite)
            self.showImportResult = true
            self.changeImportState(to: .successful)
        } catch {
            appLogger.error("Could not restore from file: \(error.localizedDescription)")
            self.changeImportState(to: .error)
        }
    }
    
    func restore() {
        self.importState = .inProgress
        if backup == nil {
            self.showFileImporter = true
        } else {
            self.showBackupChoice = true
        }
    }
    
    func changeImportState(to state: ImportState, revert: Bool = true) {
        withAnimation {
            self.importState = state
        }
        if revert && state != .pending {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.importState = .pending
            }
        }
    }
    
}
