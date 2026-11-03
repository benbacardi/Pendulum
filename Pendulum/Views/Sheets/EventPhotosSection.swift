//
//  EventPhotosSection.swift
//  Pendulum
//
//  Created by Ben Cardy on 21/11/2022.
//

import SwiftUI

/// The "Add a photo…" row, its Photo Library/Camera choice, and the thumbnail strip of whatever
/// has already been attached — one section of `AddEventSheet`'s form.
struct EventPhotosSection: View {

    @Binding var eventPhotos: [EventPhoto]
    @Binding var photoLoadPending: Bool
    @Binding var showPickerChoice: Bool
    @Binding var pickerType: UIImagePickerController.SourceType
    @Binding var showPhotoPicker: Bool

    var body: some View {
        Section {
            Button(action: {
                self.showPickerChoice = true
            }) {
                HStack {
                    Text("Add a photo…")
                    Spacer()
                    if photoLoadPending {
                        ProgressView()
                    }
                }
            }
            .confirmationDialog("Add a photo…", isPresented: $showPickerChoice) {
                Button(action: {
                    self.pickerType = .photoLibrary
                    self.showPhotoPicker = true
                    self.photoLoadPending = true
                }) {
                    Label("Photo Library", systemImage: "photo.on.rectangle")
                }
                Button(action: {
                    self.pickerType = .camera
                    self.showPhotoPicker = true
                    self.photoLoadPending = true
                }) {
                    Label("Camera", systemImage: "camera")
                }
            }
            .listRowSeparator(.hidden)
            if !eventPhotos.isEmpty {
                ScrollView(.horizontal) {
                    LazyHStack {
                        ForEach(eventPhotos) { photo in
                            if let image = photo.thumbnail() ?? photo.image() {
                                ZStack(alignment: .topTrailing) {
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(.rect(cornerRadius: 10))
                                    Button(role: .destructive, action: {
                                        let _ = withAnimation {
                                            self.eventPhotos = self.eventPhotos.filter { $0.id != photo.id }
                                        }
                                    }) {
                                        ZStack(alignment: .topTrailing) {
                                            Rectangle()
                                                .fill(.clear)
                                                .frame(width: 30, height: 30)
                                            Label("Delete", systemImage: "minus.circle.fill")
                                                .font(.headline)
                                                .labelStyle(.iconOnly)
                                                .foregroundStyle(.gray)
                                                .background(.white)
                                                .clipShape(Circle())
                                        }
                                    }
                                    .contentShape(Rectangle())
                                    .buttonStyle(.plain)
                                    .offset(x: 5, y: -5)
                                }
                            }
                        }
                    }
                    .padding(.top, 5)
                    .padding([.horizontal, .bottom])
                }
                .scrollIndicators(.hidden)
                .listRowInsets(EdgeInsets())
            }
        }
    }
}
