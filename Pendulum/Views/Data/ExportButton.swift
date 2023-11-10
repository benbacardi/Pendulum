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
    var name: String { url.lastPathComponent }
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
    @Binding var backup: Backup?
    
    @State private var exportState: ExportState = .pending
    @State private var showSuccessAlert: Bool = false
    @State private var showOverwriteConfirmation: Bool = false
    
    var body: some View {
        Section {
            Button(action: {
                if backup != nil {
                    showOverwriteConfirmation = true
                } else {
                    export()
                }
            }) {
                HStack {
                    Text("Generate Backup Archive…")
                    Spacer()
                    switch exportState {
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
            .disabled(exportState == .inProgress)
            .onChange(of: exportState) { newValue in
                if newValue == .successful {
                    showSuccessAlert = true
                }
            }
            .alert("Backup file generated!", isPresented: $showSuccessAlert) {
            } message: {
                Text("The archive will be available in the app, or you can save it elsewhere for safe keeping.")
            }
            .alert("Are you sure?", isPresented: $showOverwriteConfirmation) {
                Button("Continue") {
                    export()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                if let backup = backup, let date = backup.url.creationDate {
                    Text("This will overwrite the previous backup archive, created ") + Text(date, format: .dateTime) + Text(".")
                } else {
                    Text("")
                }
            }
            if exportState != .inProgress, let backup = backup {
                ShareLink(item: backup, preview: .init(backup.name, image: Image(.pendulum))) {
                    HStack {
                        VStack {
                            Text(backup.name)
                                .lineLimit(1)
                                .fullWidth()
                                .foregroundStyle(Color.primary)
                            Group {
                                if let date = backup.url.creationDate {
                                    Text("\(backup.url.fileSizeString) - ") + Text(date, format: .dateTime)
                                } else {
                                    Text(backup.url.fileSizeString)
                                }
                            }
                            .font(.caption)
                            .fullWidth()
                            .foregroundStyle(Color.secondary)
                        }
                        Image(systemName: "arrow.down.circle")
                            .font(.title2)
                    }
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive, action: deleteLocalArchive, label: {
                        Label("Delete", systemImage: "trash")
                    })
                }
                .contextMenu {
                    Button(role: .destructive, action: deleteLocalArchive, label: {
                        Label("Delete", systemImage: "trash")
                    })
                }
            }
        } header: {
            Text("Backup")
        } footer: {
            Text("Pendulum will create an archive file containing all your Pen Pal data, including logged events, stationery, and photos. This archive can be used to import your data back into the app at a later date. It can be quite large if you have many photos within the app.")
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
    
    func deleteLocalArchive() {
        if let backup = self.backup {
            withAnimation {
                let backupUrl = backup.url
                Task {
                    try? FileManager.default.removeItem(at: backupUrl)
                }
                self.backup = nil
                UserDefaults.shared.exportURL = nil
            }
        }
    }
    
    func export() {
        exportState = .inProgress
        Task {
            let exportService = ExportService()
            do {
                let exportURL = try exportService.export(from: moc)
                withAnimation {
                    self.backup = Backup(url: exportURL)
                    UserDefaults.shared.exportURL = exportURL
                }
                self.changeExportState(to: .successful)
            } catch {
                appLogger.error("Could not export data: \(error.localizedDescription)")
                self.changeExportState(to: .error)
            }
        }
    }
    
}

#Preview {
    Form {
        ExportButton(backup: .constant(nil))
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
