//
//  ManualAddPenPalSheet.swift
//  Pendulum
//
//  Created by Ben Cardy on 26/11/2022.
//

import SwiftUI
import PhotosUI

struct ManualAddPenPalSheet: View {
    
    // MARK: Environment
    @Environment(\.managedObjectContext) var moc
    @Environment(\.presentationMode) var presentationMode
    
    // MARK: Parameters
    var penpal: PenPal? = nil
    
    // MARK: State
    @State private var name: String = ""
    @State private var imageData: Data? = nil
    @State private var selectedPhoto: PhotosPickerItem? = nil
    
    // MARK: Parameters
    var done: (() -> ())? = nil
    
    var initials: String {
        if name.isEmpty {
            return "?"
        }
        let parts = name.split(separator: " ")
        if parts.count == 1 {
            return "\(name.prefix(1))".uppercased()
        }
        if let first = parts.first, let last = parts.last {
            return "\(first.prefix(1))\(last.prefix(1))".uppercased()
        }
        return "??"
    }
    
    @ViewBuilder
    var sectionHeader: some View {
        HStack {
            Spacer()
            VStack {
                if let imageData = self.imageData, let image = UIImage(data: imageData) {
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: image).resizable()
                            .clipShape(Circle())
                            .frame(width: 80, height: 80)
                        Button(role: .destructive, action: {
                            let _ = withAnimation {
                                self.imageData = nil
                            }
                        }) {
                            Label("Delete", systemImage: "x.circle.fill")
                                .font(.headline)
                                .labelStyle(.iconOnly)
                                .foregroundColor(.gray)
                        }
                        .buttonStyle(.plain)
                        .background {
                            Circle()
                                .fill(.white)
                        }
                    }
                } else {
                    ZStack {
                        Circle()
                            .fill(.gray)
                        Text(initials)
                            .font(.system(.title, design: .rounded))
                            .bold()
                            .foregroundColor(.white)
                    }
                    .frame(width: 80, height: 80)
                }
                PhotosPicker(
                    selection: $selectedPhoto,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Text(imageData == nil ? "Add Photo" : "Change Photo")
                        .font(.caption)
                }
                .onChange(of: selectedPhoto) { newItem in
                    Task {
                        appLogger.debug("Selected photo: \(newItem.debugDescription)")
                        do {
                            if let data = try await newItem?.loadTransferable(type: Data.self) {
                                DispatchQueue.main.async {
                                    withAnimation {
                                        imageData = data
                                    }
                                }
                            }
                        } catch {
                            appLogger.debug("Could not load transferable: \(error.localizedDescription)")
                        }
                    }
                }
            }
            Spacer()
        }
        .padding(.bottom)
        .textCase(nil)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: sectionHeader) {
                    TextField("Name", text: $name)
                }
            }
            .navigationBarTitle(self.penpal == nil ? "Add Pen Pal" : "Update Pen Pal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Cancel")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            if let penpal = penpal {
                                penpal.update(name: name, initials: initials, image: imageData)
                                if let done = done {
                                    done()
                                } else {
                                    presentationMode.wrappedValue.dismiss()
                                }
                            } else {
                                let newPenPal = PenPal(context: moc)
                                newPenPal.id = UUID()
                                newPenPal.name = name
                                newPenPal.initials = initials
                                newPenPal.image = imageData
                                newPenPal.lastEventType = EventType.noEvent
                                do {
                                    try moc.save()
                                    if let done = done {
                                        done()
                                    } else {
                                        presentationMode.wrappedValue.dismiss()
                                    }
                                } catch {
                                    dataLogger.error("Could not save manual PenPal: \(error.localizedDescription)")
                                }
                            }
                        }
                    }) {
                        Text(self.penpal == nil ? "Add" : "Save")
                    }
                    .disabled(self.name.isEmpty)
                }
            }
        }
        .task {
            if let penpal = penpal {
                self.name = penpal.wrappedName
                self.imageData = penpal.image
            }
        }
    }
}

struct ManualAddPenPalSheet_Previews: PreviewProvider {
    static var previews: some View {
        ManualAddPenPalSheet()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
