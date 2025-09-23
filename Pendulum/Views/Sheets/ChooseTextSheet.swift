//
//  ChooseTextSheet.swift
//  Pendulum
//
//  Created by Ben Cardy on 10/11/2022.
//

import SwiftUI

struct TextOptions: Identifiable {
    let id = UUID()
    let text: Binding<String>
    let options: [String]
    let title: String
}

struct ChooseTextSheet: View {
    
    // MARK: Environment
    @Environment(\.presentationMode) var presentationMode
    
    // MARK: External State
    @Binding var text: String
    
    // MARK: Parameters
    let options: [String]
    let title: String
    
    // MARK: State
    @State private var chosenOptions: [String] = []
    @State private var typedOptions: [String] = []
    @State private var loaded: Bool = false
    
    var allOptions: [String] {
        options.sorted() + typedOptions
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(allOptions, id: \.self) { option in
                    Button(action: {
                        if self.chosenOptions.contains(option) {
                            self.chosenOptions = self.chosenOptions.filter { $0 != option }
                        } else {
                            self.chosenOptions.append(option)
                        }
                    }) {
                        HStack {
                            Text(option)
                                .foregroundColor(.primary)
                            Spacer()
                            if chosenOptions.contains(option) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.adequatelyGinger)
                            }
                        }
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Label("Done", systemImage: "xmark")
                            .labelStyleIconOnlyOn26()
                    }
                }
            }
            .onChange(of: chosenOptions) {
                guard self.loaded else { return }
                self.text = self.chosenOptions.joined(separator: "\n")
            }
            .onAppear {
                self.chosenOptions = self.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? [] : self.text.components(separatedBy: Event.optionSeparators).map { $0.trimmingCharacters(in: .whitespaces) }
                self.typedOptions = self.chosenOptions.filter { !self.options.contains($0) }
                self.loaded = true
            }
        }
    }
}

struct ChooseTextSheet_Previews: PreviewProvider {
    static var previews: some View {
        ChooseTextSheet(text: .constant(""), options: ["One", "Two"], title: "Choose Something")
    }
}
