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
    let done: (PenPal) -> ()
    
    // MARK: State
    @State private var name: String = ""
    @State private var imageData: Data? = nil
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var imageLoading: Bool = false
    
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
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .clipShape(Circle())
                            .frame(width: 80, height: 80)
                        if imageLoading {
                            ProgressView()
                        }
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
                        if imageLoading {
                            ProgressView()
                        } else {
                            Text(initials)
                                .font(.system(.title, design: .rounded))
                                .bold()
                                .foregroundColor(.white)
                        }
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
                    self.imageLoading = true
                    self.imageData = nil
                    Task {
                        appLogger.debug("Selected photo: \(newItem.debugDescription)")
                        do {
                            if let data = try await newItem?.loadTransferable(type: Data.self) {
                                DispatchQueue.main.async {
                                    withAnimation {
                                        self.imageData = data
                                        self.imageLoading = false
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
                        Label("Cancel", systemImage: "xmark")
                            .labelStyleIconOnlyOn26()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: {
                        Task {
                            if let penpal = penpal {
                                penpal.update(name: name, initials: initials, image: imageData, in: moc)
                                done(penpal)
                            } else {
                                let newPenPal = PenPal(context: moc)
                                newPenPal.id = UUID()
                                newPenPal.name = name
                                newPenPal.initials = initials
                                newPenPal.image = imageData
                                newPenPal.lastEventType = EventType.noEvent
                                do {
                                    try moc.save()
                                    done(newPenPal)
                                } catch {
                                    dataLogger.error("Could not save manual PenPal: \(error.localizedDescription)")
                                }
                            }
                        }
                    }) {
                        Label(self.penpal == nil ? "Add" : "Save", systemImage: "checkmark")
                            .labelStyleIconOnlyOn26()
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
        ManualAddPenPalSheet() { newPenPal in
            
        }
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
