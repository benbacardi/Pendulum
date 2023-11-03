//
//  ExportButton.swift
//  Pendulum
//
//  Created by Ben Cardy on 01/11/2023.
//

import SwiftUI
import UniformTypeIdentifiers


struct JSONFile: FileDocument {
    static var readableContentTypes = [UTType.json]

    // by default our document is empty
    var data: Data = Data()

    // a simple initializer that creates new, empty documents
    init(from: Data) {
        self.data = from
    }

    // this initializer loads data that has been saved previously
    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            self.data = data
        }
    }

    // this will be called when the system wants to write our data to disk
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return FileWrapper(regularFileWithContents: self.data)
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
    @State private var document: JSONFile? = nil
    @State private var showFileExporter: Bool = false
    
    var body: some View {
        Button(action: export) {
            HStack {
                Text("Export Data Backup")
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
        .fileExporter(isPresented: $showFileExporter, document: document, contentType: .json, defaultFilename: "PendulumExport.json") { result in
            switch result {
            case .success(let url):
                appLogger.debug("Saved export to \(url)")
                self.changeExportState(to: .successful)
            case .failure(let error):
                appLogger.error("Could not save export: \(error.localizedDescription)")
                self.changeExportState(to: .error)
            }
        }
        .onChange(of: showFileExporter) { newValue in
            if !showFileExporter && self.exportState == .inProgress {
                self.exportState = .pending
            }
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
            do {
                let exportData = try Export(from: moc).asJSON()
                self.document = JSONFile(from: exportData)
                self.showFileExporter = true
            } catch {
                appLogger.error("Could not export data: \(error.localizedDescription)")
                self.changeExportState(to: .error)
            }
        }
    }
    
}

#Preview {
    ExportButton()
}
