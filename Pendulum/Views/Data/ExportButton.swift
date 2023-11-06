//
//  ExportButton.swift
//  Pendulum
//
//  Created by Ben Cardy on 01/11/2023.
//

import SwiftUI
import UniformTypeIdentifiers


struct Backup: Transferable {
    let url: URL
    let name: String
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .zip) { backup in
            SentTransferredFile(backup.url)
        }
    }
}

enum ExportState {
    case pending
    case inProgress
    case successful
    case error
}

struct ExportButton: View {
    
    // MARK: Environment
    @Environment(\.managedObjectContext) var moc
    
    // MARK: State
    @State private var exportState: ExportState = .pending
    @State private var backup: Backup? = nil
    
    var body: some View {
        Section {
            Button(action: export) {
                HStack {
                    Text("Generate Backup File…")
                    Spacer()
                    switch exportState {
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
            .disabled(exportState == .inProgress)
            if exportState != .inProgress, let backup = backup {
                ShareLink(item: backup, preview: .init(backup.name, image: Image(.pendulum))) {
                    HStack {
                        Image(systemName: "arrow.down.circle")
                        Text("Save…")
                            .fullWidth()
                        Text(backup.url.fileSizeString)
                            .foregroundStyle(Color.secondary)
                    }
                }
            }
        } footer: {
            Text("Pendulum will export a single file containing all your Pen Pal data, including logged events, stationery, and photos. This file can be used to import your data back into the app at a later date. It can be quite large if you have many photos within the app.")
        }
    }
    
    func changeExportState(to state: ExportState, revert: Bool = true) {
        withAnimation {
            self.exportState = state
        }
        if revert && state != .pending {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.exportState = .pending
            }
        }
    }
    
    func export() {
        exportState = .inProgress
        Task {
            let export = Export(from: moc)
            do {
                let exportURL = try export.export()
                withAnimation {
                    self.backup = Backup(url: exportURL, name: export.name)
                }
                self.changeExportState(to: .successful)
            } catch {
                appLogger.error("Could not export data: \(error.localizedDescription)")
                self.changeExportState(to: .error)
            }
        }
    }
    
}
