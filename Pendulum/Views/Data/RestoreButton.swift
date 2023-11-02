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
    @State private var showFileImporter: Bool = false
    @State private var importState: ImportState = .pending
    @State private var importResult: ImportResult? = nil
    @State private var showImportResult: Bool = false
    
    var body: some View {
        Button(action: restore) {
            HStack {
                Text("Restore from Backup")
                Spacer()
                switch importState {
                case .pending:
                    EmptyView()
                case .inProgress:
                    ProgressView()
                case .successful:
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.green)
                case .error:
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(Color.red)
                }
            }
        }
        .disabled(importState == .inProgress)
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.json]) { result in
            switch result {
            case .success(let file):
                do {
                    self.importResult = try Export.restore(from: file, to: moc)
                    self.showImportResult = true
                } catch {
                    appLogger.error("Could not restore from file: \(error.localizedDescription)")
                    self.changeImportState(to: .error)
                }
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
    }
    
    func restore() {
        self.importState = .inProgress
        self.showFileImporter = true
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

#Preview {
    RestoreButton()
}
